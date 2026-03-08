import XCTest
@testable import MemoVoice

final class TimeFormattersTests: XCTestCase {
    func testSRTTimecode() {
        XCTAssertEqual(TimeFormatters.srtTimecode(from: 0), "00:00:00,000")
        XCTAssertEqual(TimeFormatters.srtTimecode(from: 12.34), "00:00:12,340")
        XCTAssertEqual(TimeFormatters.srtTimecode(from: 65.5), "00:01:05,500")
        XCTAssertEqual(TimeFormatters.srtTimecode(from: 3661.123), "01:01:01,123")
    }

    func testDisplayTime() {
        XCTAssertEqual(TimeFormatters.displayTime(from: 0), "0:00")
        XCTAssertEqual(TimeFormatters.displayTime(from: 65), "1:05")
        XCTAssertEqual(TimeFormatters.displayTime(from: 3661), "1:01:01")
    }

    func testSegmentTimecode() {
        XCTAssertEqual(TimeFormatters.segmentTimecode(from: 0), "00:00.0")
        XCTAssertEqual(TimeFormatters.segmentTimecode(from: 12.34), "00:12.3")
        XCTAssertEqual(TimeFormatters.segmentTimecode(from: 3661.5), "1:01:01.5")
    }
}
