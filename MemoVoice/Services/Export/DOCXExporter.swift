import Foundation

/// DOCX exporter using a simple OpenXML structure
/// Self-contained without external dependencies
enum DOCXExporter {
    /// Export segments to a DOCX file
    static func write(
        title: String,
        segments: [TranscriptionSegment],
        to url: URL,
        includeTimecodes: Bool = true,
        includeTranslation: Bool = false
    ) throws {
        let xml = generateDocumentXML(
            title: title,
            segments: segments,
            includeTimecodes: includeTimecodes,
            includeTranslation: includeTranslation
        )

        // Create the DOCX package (which is a ZIP file)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create directory structure
        let wordDir = tempDir.appendingPathComponent("word")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")
        try FileManager.default.createDirectory(at: wordDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: wordRelsDir, withIntermediateDirectories: true)

        // Write files
        try contentTypesXML.write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try relsXML.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try wordRelsXML.write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try xml.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)

        // Create ZIP
        try? FileManager.default.removeItem(at: url)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", url.path, "."]
        process.currentDirectoryURL = tempDir
        try process.run()
        process.waitUntilExit()
    }

    private static func generateDocumentXML(
        title: String,
        segments: [TranscriptionSegment],
        includeTimecodes: Bool,
        includeTranslation: Bool
    ) -> String {
        var paragraphs = ""

        // Title
        paragraphs += """
        <w:p>
            <w:pPr><w:pStyle w:val="Title"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="48"/></w:rPr><w:t>\(escapeXML(title))</w:t></w:r>
        </w:p>
        """

        // Segments
        for segment in segments {
            var runs = ""

            if includeTimecodes {
                runs += """
                <w:r><w:rPr><w:color w:val="888888"/><w:sz w:val="18"/></w:rPr><w:t xml:space="preserve">[\(segment.displayStartTime)] </w:t></w:r>
                """
            }

            runs += """
            <w:r><w:t xml:space="preserve">\(escapeXML(segment.text))</w:t></w:r>
            """

            paragraphs += "<w:p>\(runs)</w:p>\n"

            if includeTranslation, let translated = segment.translatedText {
                paragraphs += """
                <w:p>
                    <w:r><w:rPr><w:color w:val="2E66FF"/><w:i/></w:rPr><w:t xml:space="preserve">\(escapeXML(translated))</w:t></w:r>
                </w:p>
                """
            }
        }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:body>
                \(paragraphs)
            </w:body>
        </w:document>
        """
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
    </Types>
    """

    private static let relsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
    </Relationships>
    """

    private static let wordRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    </Relationships>
    """
}
