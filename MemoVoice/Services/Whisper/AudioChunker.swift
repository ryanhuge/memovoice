import Foundation
import AVFoundation

struct AudioChunk: Sendable {
    let index: Int
    let startTime: Double
    let endTime: Double
    let overlapDuration: Double
}

enum AudioChunker {
    /// Split audio into chunks for processing long files
    static func createChunks(
        totalDuration: Double,
        chunkDuration: Double = 30.0,
        overlap: Double = 2.0
    ) -> [AudioChunk] {
        guard totalDuration > 0 else { return [] }

        // If short enough, process as single chunk
        if totalDuration <= chunkDuration {
            return [AudioChunk(index: 0, startTime: 0, endTime: totalDuration, overlapDuration: 0)]
        }

        var chunks: [AudioChunk] = []
        var offset: Double = 0
        var index = 0

        while offset < totalDuration {
            let end = min(offset + chunkDuration, totalDuration)
            let chunkOverlap = index == 0 ? 0 : overlap

            chunks.append(AudioChunk(
                index: index,
                startTime: offset,
                endTime: end,
                overlapDuration: chunkOverlap
            ))

            offset += chunkDuration - overlap
            index += 1
        }

        return chunks
    }

    /// Get the audio duration of a file
    static func getAudioDuration(url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    /// Extract a chunk of audio from a file to a temporary WAV file
    static func extractChunk(
        from sourceURL: URL,
        chunk: AudioChunk,
        outputURL: URL
    ) async throws {
        let asset = AVURLAsset(url: sourceURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ChunkerError.exportFailed("Could not create export session")
        }

        let startTime = CMTime(seconds: chunk.startTime, preferredTimescale: 44100)
        let endTime = CMTime(seconds: chunk.endTime, preferredTimescale: 44100)
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw ChunkerError.exportFailed(exportSession.error?.localizedDescription ?? "Unknown error")
        }
    }

    /// Merge segments from multiple chunks, handling overlap deduplication
    static func mergeSegments(
        _ chunkResults: [[TranscriptionSegment]],
        chunks: [AudioChunk]
    ) -> [TranscriptionSegment] {
        guard !chunkResults.isEmpty else { return [] }

        var allSegments: [TranscriptionSegment] = []
        var globalIndex = 0

        for (chunkIndex, segments) in chunkResults.enumerated() {
            let chunk = chunks[chunkIndex]

            for segment in segments {
                // Adjust timestamps to global timeline
                let adjustedStart = segment.startTime + chunk.startTime
                let adjustedEnd = segment.endTime + chunk.startTime

                // Skip segments in the overlap region of previous chunk
                if chunkIndex > 0 {
                    let overlapEnd = chunk.startTime + chunk.overlapDuration
                    if adjustedStart < overlapEnd {
                        continue
                    }
                }

                let mergedSegment = TranscriptionSegment(
                    index: globalIndex,
                    startTime: adjustedStart,
                    endTime: adjustedEnd,
                    text: segment.text,
                    confidence: segment.confidence
                )
                allSegments.append(mergedSegment)
                globalIndex += 1
            }
        }

        return allSegments
    }

    enum ChunkerError: LocalizedError {
        case exportFailed(String)

        var errorDescription: String? {
            switch self {
            case .exportFailed(let msg):
                "Audio chunk export failed: \(msg)"
            }
        }
    }
}
