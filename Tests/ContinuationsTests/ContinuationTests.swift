@testable
import Continuations
import Foundation
import XCTest

final class ContinuationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _TestSupport.disableAssertions()
    }

    override func tearDown() {
        super.tearDown()
        _TestSupport.enableAssertions()
    }

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
        XCTAssertFalse(wasRun)
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
        XCTAssertEqual(value, 0)
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume(returning: expected)
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
        XCTAssertEqual(runCount, 0)
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
        XCTAssertFalse(wasRun)
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
        XCTAssertEqual(value, 0)
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resumeFailure(returning: expected)
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
        XCTAssertEqual(runCount, 0)
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

    #if TEST_DEPRECATED_WARNINGS
    func testWarningResumeFailureWhenErrorType() {
        struct E: Error {}
        var wasCalled = false
        let c = Continuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            wasCalled = true
        }
        XCTAssertFalse(wasCalled)
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resumeFailure(returning: E())
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertTrue(wasCalled)
    }
    #endif

    func testResumeFailureWhenErrorType() {
        struct E: Error {}
        var runCount = 0
        let c = Continuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            runCount += 1
        }
        XCTAssertEqual(runCount, 0)
        func callFunction<T: _TestResumeFailureWhenErrorType>(on c: T) where T.ResumeFailure == E {
            c.resumeFailure(returning: E())
        }
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        callFunction(on: c)
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(runCount, 1)
        callFunction(on: c)
        XCTAssertEqual(runCount, 1)
    }

    func testResumeThrowing() {
        struct E: Error {}
        var runCount = 0
        let c = Continuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            runCount += 1
        }
        XCTAssertEqual(runCount, 0)
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume(throwing: E())
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(runCount, 1)
        c.resume(throwing: E())
        XCTAssertEqual(runCount, 1)
    }

    func testResumeWithResultSuccess() {
        struct E: Error {}
        var runCount = 0
        let c = Continuation<Void, E> {
            runCount += 1
        } onFailure: { _ in
            XCTFail("Resume function shouldn't be called")
        }
        XCTAssertEqual(runCount, 0)
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume(with: .success(Void()))
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(runCount, 1)
        c.resume(with: .success(Void()))
        XCTAssertEqual(runCount, 1)
    }

    func testResumeWithResultFailure() {
        struct E: Error {}
        var runCount = 0
        let c = Continuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            runCount += 1
        }
        XCTAssertEqual(runCount, 0)
        XCTAssertFalse(c.haveRun.load(ordering: .relaxed))
        c.resume(with: .failure(E()))
        XCTAssertTrue(c.haveRun.load(ordering: .relaxed))
        XCTAssertEqual(runCount, 1)
        c.resume(with: .failure(E()))
        XCTAssertEqual(runCount, 1)
    }
}

private protocol _TestResumeFailureWhenErrorType {
    associatedtype ResumeFailure
    func resumeFailure(returning value: ResumeFailure)
}
extension Continuation: _TestResumeFailureWhenErrorType where ResumeFailure: Error {}
