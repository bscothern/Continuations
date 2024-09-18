//
//  Continuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2024 Braden Scothern. All rights reserved.
//

import Atomics

/// A continuation is a context that should be resumed or failed in the future to continue running some asynchronous operation.
///
/// Unlike when a callback is executed when a continuation has its success or failure known right away.
///
/// There is also the benefit of it is guaranteed in a thread safe way that a `Continuation` can only be resumed a single time.
/// If `resume(returning:)` or `resumeFailure(returning:)` or `resume(throwing:)` is called more than once or after the other resume function has been called then nothing will happen in release mode and an assertion will be raised in debug mode.
public class Continuation<ResumeValue, ResumeFailure>: UncheckedContinuation<ResumeValue, ResumeFailure>, @unchecked Sendable {
    @usableFromInline
    var haveRun: UnsafeAtomic<Bool> = .create(false)

    @inlinable
    deinit {
        haveRun.destroy()
    }

    /// Has the continuation resume its operation in a successful manner.
    ///
    /// - Parameter value: The arguments to pass to this continuations resume function.
    @inlinable
    public override func resume(returning value: ResumeValue) {
        guard !haveRun.exchange(true, ordering: .releasing) else {
            #if DEBUG
            assert(_TestSupport.assertCondition, "A continuation should only be resumed once.")
            #endif
            return
        }
        super.resumeFunction(value)
    }

    /// Has the continuation resume its operation in a failed manner.
    ///
    /// - Parameter value: The arguments to pass to this continuations resume failed function.
    @inlinable
    public override func resumeFailure(returning value: ResumeFailure) {
        guard !haveRun.exchange(true, ordering: .releasing) else {
            #if DEBUG
            assert(_TestSupport.assertCondition, "A continuation should only be resumed once.")
            #endif
            return
        }
        super.resumeFailure(returning: value)
    }

    /// Has the continuation resume its operation in a failed manner.
    ///
    /// - Parameter error: The arguments to pass to this continuations resume failed function.
    @inlinable
    public override func resume(throwing error: ResumeFailure)
    where ResumeFailure: Error {
        guard !haveRun.exchange(true, ordering: .releasing) else {
            #if DEBUG
            assert(_TestSupport.assertCondition, "A continuation should only be resumed once.")
            #endif
            return
        }
        super.resume(throwing: error)
    }

    @inlinable
    public override func resume(with result: Result<ResumeValue, ResumeFailure>)
    where ResumeFailure: Error {
        guard !haveRun.exchange(true, ordering: .releasing) else {
            #if DEBUG
            assert(_TestSupport.assertCondition, "A continuation should only be resumed once.")
            #endif
            return
        }
        super.resume(with: result)
    }
}
