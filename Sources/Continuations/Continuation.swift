//
//  Continuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2021 Braden Scothern. All rights reserved.
//

import Atomics

/// A continuation is a context that should be resumed or failed in the future to continue running some asynchronous operation.
///
/// Unlike when a callback is executed when a continuation has its success or failure known right away.
///
/// There is also the benefit of it is guaranteed in a thread safe way that a `Continuation` can only be resumed a single time.
/// If `resume(args:)` or `resumeFailure(args:)` is called more than once or after the other resume function has been called then nothing will happen.
public class Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let resumeFunction: (_ args: ResumeArgs) -> Void
    @usableFromInline
    let resumeFailureFunction: (_ failureArgs: ResumeFailureArgs) -> Void

    @usableFromInline
    var haveRun: UnsafeAtomic<Bool> = .create(false)
    
    /// Creates a `Continuation`.
    /// 
    /// - Parameters:
    ///   - resumeFunction: The function that will be called when `resume(args:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resumeFailure(args:)` is called.
    ///   - args: The arguments to the resume function being executed.
    @inlinable
    public init(
        onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void,
        onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void
    ) {
        self.resumeFunction = resumeFunction
        self.resumeFailureFunction = resumeFailureFunction
    }

    @inlinable
    deinit {
        haveRun.destroy()
    }
    
    /// Has the `Continuation` resume its operation in a successful manner.
    ///
    /// - Parameter args: The arguments to pass to this continuations resume function.
    @inlinable
    public func resume(args: ResumeArgs) {
        guard !haveRun.exchange(true, ordering: .releasing) else { return }
        resumeFunction(args)
    }

    /// Has the `Continuation` resume its operation in a failed manner.
    ///
    /// - Parameter args: The arguments to pass to this continuations resume failed function.
    @inlinable
    public func resumeFailure(args: ResumeFailureArgs) {
        guard !haveRun.exchange(true, ordering: .releasing) else { return }
        resumeFailureFunction(args)
    }
}

extension Continuation where ResumeArgs == Void {
    /// Has the `Continuation` resume its operation in a successful manner.
    @_transparent
    public func resume() {
        resume(args: ())
    }
}

extension Continuation where ResumeFailureArgs == Void {
    /// Has the `Continuation` resume its operation in a failed manner.
    @_transparent
    public func resumeFailure() {
        resumeFailure(args: ())
    }
}
