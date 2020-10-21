//
//  GuaranteeResumeContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020 Braden Scothern. All rights reserved.
//

import Atomics

/// A `Continuation` that has the guarantee that `resume(args:)` will be called on deinit if it is not explictly continued with a `resume(args:)` or `resumeFailure(args:)`.
public final class GuaranteeResumeContinuation<ResumeArgs, ResumeFailureArgs>: Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let defaultResumeArgs: () -> ResumeArgs

    @inlinable
    public convenience init(defaultResumeArgs: @escaping @autoclosure () -> ResumeArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void) {
        self.init(defaultResumeArgs: defaultResumeArgs, onResume: resumeFunction, onFailure: { _ in })
    }

    @inlinable
    public convenience init(defaultResumeArgs: @escaping @autoclosure () -> ResumeArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.init(defaultResumeArgs: defaultResumeArgs, onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @usableFromInline
    init(defaultResumeArgs: @escaping () -> ResumeArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.defaultResumeArgs = defaultResumeArgs
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        resume(args: defaultResumeArgs())
    }
}
