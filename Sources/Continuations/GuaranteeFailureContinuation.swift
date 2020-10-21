//
//  GuaranteeFailureContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020 Braden Scothern. All rights reserved.
//

import Atomics

/// A `Continuation` that has the guarantee that `resumeFailure(args:)` will be called on deinit if it is not explictly continued with a `resume(args:)` or `resumeFailure(args:)`.
public final class GuaranteeFailureContinuation<ResumeArgs, ResumeFailureArgs>: Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let defaultResumeFailureArgs: () -> ResumeFailureArgs

    @inlinable
    public convenience init(defaultResumeFailureArgs: @escaping @autoclosure () -> ResumeFailureArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void) {
        self.init(defaultResumeFailureArgs: defaultResumeFailureArgs, onResume: resumeFunction, onFailure: { _ in })
    }

    @inlinable
    public convenience init(defaultResumeFailureArgs: @escaping @autoclosure () -> ResumeFailureArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.init(defaultResumeFailureArgs: defaultResumeFailureArgs, onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @usableFromInline
    init(defaultResumeFailureArgs: @escaping () -> ResumeFailureArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.defaultResumeFailureArgs = defaultResumeFailureArgs
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        resumeFailure(args: defaultResumeFailureArgs())
    }
}
