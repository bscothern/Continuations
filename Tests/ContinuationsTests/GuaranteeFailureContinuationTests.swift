@testable
import Continuations
import Foundation
import XCTest

final class GuaranteeFailureContinuationTests: XCTestCase {
    func testInit() {
        var done = false
        let c = GuaranteeFailureContinuation<Void, Void>(
            defaultResumeFailureArgs: { () -> Void in
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
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureArgs: expected) {
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
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureArgs: -expected) {
                XCTFail("Resume function shouldn't be called")
            } onFailure: {
                value = $0
            }
            XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
            c.resumeFailure(args: expected)
        }
        XCTAssertEqual(value, expected)
    }
    
    func testResume1() {
        var value = 0
        let expected = 0
        var hasRun: Bool = false
        do {
            let c = GuaranteeFailureContinuation<Void, Int>(defaultResumeFailureArgs: expected + 1) {
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
}
