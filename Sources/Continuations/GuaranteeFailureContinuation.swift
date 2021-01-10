//
//  GuaranteeFailureContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2021 Braden Scothern. All rights reserved.
//

import Atomics

/// A `Continuation` that has the guarantee that `resumeFailure(args:)` will be called on deinit if it is not explictly continued with a `resume(args:)` or `resumeFailure(args:)`.
public final class GuaranteeFailureContinuation<ResumeArgs, ResumeFailureArgs>: Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let defaultResumeFailureArgs: () -> ResumeFailureArgs

    /// Creates a `GuaranteeFailureContinuation`.
    /// 
    /// - Parameters:
    ///   - defaultResumeFailureArgs: An autoclosure that will be executed to supply arguments to `resumeFailure(args:)` on deinit if the continuation has not already been resumed.
    ///   - resumeFunction: The function that will be called when `resume(args:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resumeFailure(args:)` is called.
    ///   - args: The arguments to the resume function being executed.
    @inlinable
    public init(
        defaultResumeFailureArgs: @escaping @autoclosure () -> ResumeFailureArgs,
        onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void,
        onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void
    ) {
        self.defaultResumeFailureArgs = defaultResumeFailureArgs
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        resumeFailure(args: defaultResumeFailureArgs())
    }
}
