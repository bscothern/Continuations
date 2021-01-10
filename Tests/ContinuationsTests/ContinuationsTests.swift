@testable
import Continuations
import Foundation
import XCTest

final class ContinuationsTests: XCTestCase {
    func testInit() {
        let c = Continuation<Void, Void> {
            XCTFail("Continuations shouldn't call their resume function on init")
        } onFailure: {
            XCTFail("Continuations shouldn't call their resume failure function on init")
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
    }
    
    func testResume1() {
        var wasRun = false
        let c = Continuation<Void, Void> {
            wasRun = true
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume()
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertTrue(wasRun)
    }
    
    func testResume2() {
        var value: Int = 0
        let expected = 42
        let c = Continuation<Int, Void> {
            value = $0
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume(args: expected)
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(value, expected)
    }
    
    func testMultipleResume() {
        var runCount = 0
        let c = Continuation<Void, Void> {
            runCount += 1
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume()
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(runCount, 1)
        c.resume()
        XCTAssertEqual(runCount, 1)
    }
    
    func testMultipleResumeConcurrent() {
        var runCount = 0
        let c = Continuation<Void, Void> {
            runCount += 1
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            c.resume()
            XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
            XCTAssertEqual(runCount, 1)
        }
    }
    
    func testResumeFailure1() {
        var wasRun = false
        let c = Continuation<Void, Void> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            wasRun = true
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resumeFailure()
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertTrue(wasRun)
    }

    func testResumeFailure2() {
        var value: Int = 0
        let expected = 42
        let c = Continuation<Void, Int> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            value = $0
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resumeFailure(args: expected)
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(value, expected)
    }
    
    func testMultipleResumeFailure() {
        var runCount = 0
        let c = Continuation<Void, Void> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            runCount += 1
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resumeFailure()
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(runCount, 1)
        c.resumeFailure()
        XCTAssertEqual(runCount, 1)
    }
    
    func testMultipleResumeFailureConcurrent() {
        var runCount = 0
        let c = Continuation<Void, Void> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            runCount += 1
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            c.resumeFailure()
            XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
            XCTAssertEqual(runCount, 1)
        }
    }
}
