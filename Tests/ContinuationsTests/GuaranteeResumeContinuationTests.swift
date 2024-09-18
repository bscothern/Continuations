@testable
import Continuations
import Foundation
import XCTest

final class GuaranteeResumeContinuationTests: XCTestCase {
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
        let c = GuaranteeResumeContinuation<Void, Void>(
            defaultResumeValue: { () -> Void in
                if !$done.wrappedValue {
                    XCTFail("Inits shouldn't call default arguments")
                }
            }()) {
                if !$done.wrappedValue {
                    XCTFail("Continuations shouldn't call their resume function on init")
                }
            } onFailure: {
                XCTFail("Continuations shouldn't call their resume failure function on init")
            }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        done = true
    }

    func testAutoResumeWithDefaultValue() {
        @UnsafeSendableBox
        var called = false
        do {
            let c = GuaranteeResumeContinuation<Void, Void> {
                $called.wrappedValue = true
            } onFailure: {
                XCTFail("Resume failure function shouldn't be called")
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssert(called)
    }

    func testAutoResume1() {
        @UnsafeSendableBox
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeResumeContinuation<Int, Void>(defaultResumeValue: expected) {
                $value.wrappedValue = $0
            } onFailure: {
                XCTFail("Resume failure function shouldn't be called")
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
    }

    func testResume1() {
        @UnsafeSendableBox
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeResumeContinuation<Int, Void>(defaultResumeValue: -expected) {
                $value.wrappedValue = $0
            } onFailure: {
                XCTFail("Resume failure function shouldn't be called")
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resume(returning: expected)
        }
        XCTAssertEqual(value, expected)
    }

    func testResumeFailure1() {
        @UnsafeSendableBox
        var value = 0
        let expected = 0
        @UnsafeSendableBox
        var hasRun = false
        do {
            let c = GuaranteeResumeContinuation<Int, Void>(defaultResumeValue: expected + 1) {
                $value.wrappedValue = $0
            } onFailure: {
                $hasRun.wrappedValue = true
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resumeFailure()
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
            let c = GuaranteeResumeContinuation<Void, Void> { _ in
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
            c.resumeFailure()
        }
        XCTAssertEqual(runLocation, failure)
    }
}
