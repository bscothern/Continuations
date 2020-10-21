@testable import Continuations
import XCTest

final class ContinuationsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Continuations().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
