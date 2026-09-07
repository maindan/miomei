import XCTest
@testable import MioMei

final class DurationFormatterTests: XCTestCase {
    func testHoursMinutesSeconds() {
        XCTAssertEqual(5016.hoursMinutesSeconds, "01:23:36")
        XCTAssertEqual(0.hoursMinutesSeconds, "00:00:00")
    }

    func testHoursAndMinutes() {
        XCTAssertEqual(5400.hoursAndMinutes, "1h 30m")
        XCTAssertEqual(300.hoursAndMinutes, "5m")
    }
}
