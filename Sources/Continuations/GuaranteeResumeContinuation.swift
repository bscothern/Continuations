//
//  GuaranteeResumeContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2021 Braden Scothern. All rights reserved.
//

import Atomics

/// A `Continuation` that has the guarantee that `resume(args:)` will be called on deinit if it is not explictly continued with a `resume(args:)` or `resumeFailure(args:)`.
public final class GuaranteeResumeContinuation<ResumeArgs, ResumeFailureArgs>: Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let defaultResumeArgs: () -> ResumeArgs

    /// Creates a `GuaranteeResumeContinuation`.
    ///
    /// - Parameters:
    ///   - defaultResumeArgs: An autoclosure that will be executed to supply arguments to `resume(args:)` on deinit if the continuation has not already been resumed.
    ///   - resumeFunction: The function that will be called when `resume(args:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resumeFailure(args:)` is called.
    ///   - args: The arguments to the resume function being executed.
    @inlinable
    public init(
        defaultResumeArgs: @escaping @autoclosure () -> ResumeArgs,
        onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void,
        onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void
    ) {
        self.defaultResumeArgs = defaultResumeArgs
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        resume(args: defaultResumeArgs())
    }
}
