import Atomics
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
        @UnsafeSendableBox
        var done = false
        let c = GuaranteeFailureContinuation<Void, Void>(
            defaultResumeFailureValue: { () -> Void in
                if !$done.wrappedValue {
                    XCTFail("Inits shouldn't call default arguments")
                }
            }()) {
                XCTFail("Continuations shouldn't call their resume function on init")
            } onFailure: {
                if !$done.wrappedValue {
                    XCTFail("Continuations shouldn't call their resume failure function on init")
                }
            }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        done = true
    }

    func testAutoResumeFailureWithDefaultValue() {
        @UnsafeSendableBox
        var called = false
        do {
            let c = GuaranteeFailureContinuation<Void, Void> {
                XCTFail("Resume function shouldn't be called")
            } onFailure: {
                $called.wrappedValue = true
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssert(called)
    }

    func testAutoResumeFailure1() {
        @UnsafeSendableBox
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureValue: expected) {
                XCTFail("Resume function shouldn't be called")
            } onFailure: {
                $value.wrappedValue = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
    }

    func testResumeFailure1() {
        @UnsafeSendableBox
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureValue: -expected) {
                XCTFail("Resume function shouldn't be called")
            } onFailure: {
                $value.wrappedValue = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resumeFailure(returning: expected)
        }
        XCTAssertEqual(value, expected)
    }

    func testResume1() {
        @UnsafeSendableBox
        var value = 0
        let expected = 0
        @UnsafeSendableBox
        var hasRun = false
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureValue: expected + 1) {
                $hasRun.wrappedValue = true
            } onFailure: {
                $value.wrappedValue = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resume()
            XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
        XCTAssertTrue(hasRun)
    }

    func testDoesntRunOnDeinitIfAlreadyRun() {
        let success = 1
        let failure = 2
        @UnsafeSendableBox
        var runLocation: Int = 0
        do {
            let c = GuaranteeFailureContinuation<Void, Void> { _ in
                if $runLocation.wrappedValue == 0 {
                    $runLocation.wrappedValue = success
                } else {
                    XCTFail("Only one continuation function should be executed")
                }
            } onFailure: { _ in
                if $runLocation.wrappedValue == 0 {
                    $runLocation.wrappedValue = failure
                } else {
                    XCTFail("Only one continuation function should be executed")
                }
            }
            XCTAssertEqual(runLocation, 0)
            c.resume()
        }
        XCTAssertEqual(runLocation, success)
    }
}
