import XCTest
@testable import VectorClock

final class VectorClockTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(VectorClock().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
