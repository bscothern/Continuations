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
        var done = false
        let c = GuaranteeResumeContinuation<Void, Void>(
            defaultResumeValue: { () -> Void in
                if !done {
                    XCTFail("Inits shouldn't call default arguments")
                }
            }()) {
            if !done {
                XCTFail("Continuations shouldn't call their resume function on init")
            }
        } onFailure: {
            XCTFail("Continuations shouldn't call their resume failure function on init")
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        done = true
    }

    func testAutoResume1() {
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeResumeContinuation<Int, Void>(defaultResumeValue: expected) {
                value = $0
            } onFailure: {
                XCTFail("Resume failure function shouldn't be called")
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
    }

    func testResume1() {
        var value = 0
        let expected = 42
        do {
            let c = GuaranteeResumeContinuation<Int, Void>(defaultResumeValue: -expected) {
                value = $0
            } onFailure: {
                XCTFail("Resume failure function shouldn't be called")
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resume(returning: expected)
        }
        XCTAssertEqual(value, expected)
    }

    func testResumeFailure1() {
        var value = 0
        let expected = 0
        var hasRun = false
        do {
            let c = GuaranteeResumeContinuation<Int, Void>(defaultResumeValue: expected + 1) {
                value = $0
            } onFailure: {
                hasRun = true
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resumeFailure()
            XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        }
        XCTAssertEqual(value, expected)
        XCTAssertTrue(hasRun)
    }
}
