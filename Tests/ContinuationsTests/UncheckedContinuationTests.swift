@testable
import Continuations
import Foundation
import XCTest

final class UncheckedContinuationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _TestSupport.disableAssertions()
    }

    override func tearDown() {
        super.tearDown()
        _TestSupport.enableAssertions()
    }

    @inline(never)
    func _blackHole<T>(_: T) {}

    func testInit() {
        _blackHole(
            UncheckedContinuation<Void, Void> {
                XCTFail("Continuations shouldn't call their resume function on init")
            } onFailure: {
                XCTFail("Continuations shouldn't call their resume failure function on init")
            }
        )
    }

    func testResume1() {
        var wasRun = false
        let c = UncheckedContinuation<Void, Void> {
            wasRun = true
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertFalse(wasRun)
        c.resume()
        XCTAssertTrue(wasRun)
    }

    func testResume2() {
        var value: Int = 0
        let expected = 42
        let c = UncheckedContinuation<Int, Void> {
            value = $0
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertEqual(value, 0)
        c.resume(returning: expected)
        XCTAssertEqual(value, expected)
    }

    func testMultipleResume() {
        var runCount = 0
        let c = UncheckedContinuation<Void, Void> {
            runCount += 1
        } onFailure: {
            XCTFail("Resume failure function shouldn't be called")
        }
        XCTAssertEqual(runCount, 0)
        c.resume()
        XCTAssertEqual(runCount, 1)
        c.resume()
        XCTAssertEqual(runCount, 2)
    }

    func testResumeFailure1() {
        var wasRun = false
        let c = UncheckedContinuation<Void, Void> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            wasRun = true
        }
        XCTAssertFalse(wasRun)
        c.resumeFailure()
        XCTAssertTrue(wasRun)
    }

    func testResumeFailure2() {
        var value: Int = 0
        let expected = 42
        let c = UncheckedContinuation<Void, Int> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            value = $0
        }
        XCTAssertEqual(value, 0)
        c.resumeFailure(returning: expected)
        XCTAssertEqual(value, expected)
    }

    func testMultipleResumeFailure() {
        var runCount = 0
        let c = UncheckedContinuation<Void, Void> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: {
            runCount += 1
        }
        XCTAssertEqual(runCount, 0)
        c.resumeFailure()
        XCTAssertEqual(runCount, 1)
        c.resumeFailure()
        XCTAssertEqual(runCount, 2)
    }

    #if TEST_DEPRECATED_WARNINGS
    func testWarningResumeFailureWhenErrorType() {
        struct E: Error {}
        var wasCalled = false
        let c = UncheckedContinuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            wasCalled = true
        }
        XCTAssertFalse(wasCalled)
        c.resumeFailure(returning: E())
        XCTAssertTrue(wasCalled)
    }
    #endif

    func testResumeFailureWhenErrorType() {
        struct E: Error {}
        var wasCalled = false
        let c = UncheckedContinuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            wasCalled = true
        }
        XCTAssertFalse(wasCalled)
        func callFunction<T: _TestResumeFailureWhenErrorType>(on c: T) where T.ResumeFailure == E {
            c.resumeFailure(returning: E())
        }
        callFunction(on: c)
        XCTAssertTrue(wasCalled)
    }

    func testResumeThrowing() {
        struct E: Error {}
        var wasCalled = false
        let c = UncheckedContinuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            wasCalled = true
        }
        XCTAssertFalse(wasCalled)
        c.resume(throwing: E())
        XCTAssertTrue(wasCalled)
    }

    func testResumeWithResultSuccess() {
        struct E: Error {}
        var wasCalled = false
        let c = UncheckedContinuation<Void, E> {
            wasCalled = true
        } onFailure: { _ in
            XCTFail("Resume function shouldn't be called")
        }
        XCTAssertFalse(wasCalled)
        c.resume(with: .success(Void()))
        XCTAssertTrue(wasCalled)
    }

    func testResumeWithResultFailure() {
        struct E: Error {}
        var wasCalled = false
        let c = UncheckedContinuation<Void, E> {
            XCTFail("Resume function shouldn't be called")
        } onFailure: { _ in
            wasCalled = true
        }
        XCTAssertFalse(wasCalled)
        c.resume(with: .failure(E()))
        XCTAssertTrue(wasCalled)
    }
}

private protocol _TestResumeFailureWhenErrorType {
    associatedtype ResumeFailure
    func resumeFailure(returning value: ResumeFailure)
}
extension UncheckedContinuation: _TestResumeFailureWhenErrorType where ResumeFailure: Error {}
