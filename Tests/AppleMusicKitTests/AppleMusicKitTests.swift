import XCTest
@testable import AppleMusicKit

final class AppleMusicKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AppleMusicKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
