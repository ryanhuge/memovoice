import Foundation
import os

private let logger = Logger(subsystem: "com.memovoice", category: "ProcessRunner")

enum ProcessRunner {
    struct ProcessResult: Sendable {
        let exitCode: Int32
        let stdout: String
        let stderr: String

        var isSuccess: Bool { exitCode == 0 }
    }

    enum ProcessError: LocalizedError {
        case executableNotFound(String)
        case executionFailed(String)
        case timeout

        var errorDescription: String? {
            switch self {
            case .executableNotFound(let path):
                "Executable not found at \(path)"
            case .executionFailed(let message):
                "Process execution failed: \(message)"
            case .timeout:
                "Process timed out"
            }
        }
    }

    /// Thread-safe continuation wrapper
    private final class ContinuationBox: @unchecked Sendable {
        private var continuation: CheckedContinuation<ProcessResult, Error>?
        private let lock = NSLock()

        init(_ continuation: CheckedContinuation<ProcessResult, Error>) {
            self.continuation = continuation
        }

        func resume(with result: Result<ProcessResult, Error>) {
            lock.lock()
            let cont = continuation
            continuation = nil
            lock.unlock()
            cont?.resume(with: result)
        }
    }

    /// Configure process executable.
    /// macOS Hardened Runtime + com.apple.provenance blocks GUI apps from executing
    /// Homebrew-installed scripts (e.g. Node.js CLI tools). Two strategies:
    /// 1. For .js/.mjs scripts: resolve symlink, run via `node <script>` — node is a
    ///    Mach-O binary without provenance, so it can read any script file.
    /// 2. For compiled binaries (ffmpeg, yt-dlp): use /usr/bin/env trampoline.
    private static func configureExecutable(_ path: String, arguments: [String], for process: Process) {
        // Resolve symlinks to find the actual target file
        let resolvedURL = URL(fileURLWithPath: path).resolvingSymlinksInPath()
        let resolvedPath = resolvedURL.path
        let ext = resolvedURL.pathExtension.lowercased()

        if ext == "js" || ext == "mjs" || ext == "cjs" || ext == "ts" {
            // Node.js script — run via interpreter to bypass provenance check
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["node", resolvedPath] + arguments
            logger.info("Using node interpreter: node \(resolvedPath) \(arguments.joined(separator: " "))")
        } else {
            // Compiled binary — use env trampoline for PATH lookup
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            let toolName = URL(fileURLWithPath: path).lastPathComponent
            process.arguments = [toolName] + arguments
            logger.info("Using /usr/bin/env trampoline: env \(toolName) \(arguments.joined(separator: " "))")
        }
    }

    /// Build a process environment with common tool paths included
    private static func buildEnvironment(extra: [String: String]? = nil) -> [String: String] {
        var processEnv = ProcessInfo.processInfo.environment
        // Clear CLAUDECODE to avoid nested session errors
        processEnv.removeValue(forKey: "CLAUDECODE")
        // Ensure common tool paths are in PATH (macOS GUI apps have minimal PATH)
        let currentPath = processEnv["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let extraPaths = ["/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin"]
        let missingPaths = extraPaths.filter { !currentPath.contains($0) }
        if !missingPaths.isEmpty {
            processEnv["PATH"] = (missingPaths + [currentPath]).joined(separator: ":")
        }
        if let extra {
            for (key, value) in extra {
                processEnv[key] = value
            }
        }
        return processEnv
    }

    /// Run an external process asynchronously
    static func run(
        executablePath: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        workingDirectory: URL? = nil,
        stdinData: Data? = nil,
        timeout: TimeInterval = 300
    ) async throws -> ProcessResult {
        logger.info("run: \(executablePath) \(arguments.joined(separator: " "))")

        // No pre-flight executable check — macOS security restrictions (Hardened Runtime)
        // can cause access()/isExecutableFile() to return false even for valid executables.
        // Instead, let Process.run() handle validation via posix_spawn().

        return try await withCheckedThrowingContinuation { continuation in
            let box = ContinuationBox(continuation)

            let process = Process()
            configureExecutable(executablePath, arguments: arguments, for: process)
            process.environment = buildEnvironment(extra: environment)

            if let wd = workingDirectory {
                process.currentDirectoryURL = wd
            }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            // Accumulate stdout/stderr incrementally to avoid pipe buffer deadlock
            let stdoutAccumulator = DataAccumulator()
            let stderrAccumulator = DataAccumulator()

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stdoutAccumulator.append(data)
                }
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stderrAccumulator.append(data)
                }
            }

            // Setup stdin pipe
            var stdinPipe: Pipe?
            if stdinData != nil {
                stdinPipe = Pipe()
                process.standardInput = stdinPipe
            }

            process.terminationHandler = { _ in
                // Clean up readability handlers
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                // Read any remaining data
                let remainingStdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let remainingStderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                if !remainingStdout.isEmpty { stdoutAccumulator.append(remainingStdout) }
                if !remainingStderr.isEmpty { stderrAccumulator.append(remainingStderr) }

                let result = ProcessResult(
                    exitCode: process.terminationStatus,
                    stdout: String(data: stdoutAccumulator.data, encoding: .utf8) ?? "",
                    stderr: String(data: stderrAccumulator.data, encoding: .utf8) ?? ""
                )
                logger.info("Process exited: \(process.terminationStatus), stdout: \(result.stdout.prefix(200)), stderr: \(result.stderr.prefix(200))")
                box.resume(with: .success(result))
            }

            // Start process FIRST, then write stdin
            do {
                try process.run()
                logger.info("Process started successfully (pid: \(process.processIdentifier))")
            } catch {
                logger.error("Process.run() failed: \(error.localizedDescription)")
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                box.resume(with: .failure(ProcessError.executionFailed(error.localizedDescription)))
                return
            }

            // Write stdin data AFTER process starts, on background queue to avoid blocking
            if let data = stdinData, let pipe = stdinPipe {
                DispatchQueue.global().async {
                    pipe.fileHandleForWriting.write(data)
                    pipe.fileHandleForWriting.closeFile()
                }
            }

            // Timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning {
                    process.terminate()
                    box.resume(with: .failure(ProcessError.timeout))
                }
            }
        }
    }

    /// Run a process and stream its output line by line
    static func runStreaming(
        executablePath: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        let process = Process()
        configureExecutable(executablePath, arguments: arguments, for: process)
        process.environment = buildEnvironment(extra: environment)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                onOutput(line)
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                onOutput(line)
            }
        }

        try process.run()
        process.waitUntilExit()

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        return process.terminationStatus
    }

    /// Thread-safe data accumulator for pipe output
    private final class DataAccumulator: @unchecked Sendable {
        private var _data = Data()
        private let lock = NSLock()

        func append(_ newData: Data) {
            lock.lock()
            _data.append(newData)
            lock.unlock()
        }

        var data: Data {
            lock.lock()
            let copy = _data
            lock.unlock()
            return copy
        }
    }
}
