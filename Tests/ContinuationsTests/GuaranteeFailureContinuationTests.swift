@testable
import Continuations
import Foundation
import XCTest

final class GuaranteeFailureContinuationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _TestSupport.disableAssertions()
    }

    override func tearDown() {
        super.tearDown()
        _TestSupport.enableAssertions()
    }

    func testInit() {
        var done = false
        let c = GuaranteeFailureContinuation<Void, Void>(
            defaultResumeFailureValue: { () -> Void in
                if !done {
                    XCTFail("Inits shouldn't call default arguments")
                }
        }()) {
            XCTFail("Continuations shouldn't call their resume function on init")
        } onFailure: {
            if !done {
                XCTFail("Continuations shouldn't call their resume failure function on init")
            }
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        done = true
    }

    func testAutoResumeFailure1() {
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureValue: expected) {
                XCTFail("Resume failure function shouldn't be called")
            } onFailure: {
                value = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
    }

    func testResumeFailure1() {
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureValue: -expected) {
                XCTFail("Resume function shouldn't be called")
            } onFailure: {
                value = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resumeFailure(returning: expected)
        }
        XCTAssertEqual(value, expected)
    }

    func testResume1() {
        var value = 0
        let expected = 0
        var hasRun = false
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureValue: expected + 1) {
                hasRun = true
            } onFailure: {
                value = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resume()
            XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
        XCTAssertTrue(hasRun)
    }

    func testDoesntRunOnDeinitIfAlreadyRun() {
        enum RunLocation {
            case success
            case failure
        }
        var runLocation: RunLocation?
        do {
            let c = GuaranteeFailureContinuation<Void, Void> { _ in
                if runLocation == nil {
                    runLocation = .success
                }
            } onFailure: { _ in
                if runLocation == nil {
                    runLocation = .failure
                }
            }
            XCTAssertNil(runLocation)
            c.resume()
        }
        XCTAssertEqual(runLocation, .success)
    }
}
