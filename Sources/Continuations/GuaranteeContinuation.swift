//
//  GuaranteeContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020 Braden Scothern. All rights reserved.
//

import Atomics

public final class GuaranteeContinuation<ResumeArgs, ResumeFailureArgs>: Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let defaultResumeArgs: (() -> ResumeArgs)?

    @usableFromInline
    let defaultResumeFailureArgs: (() -> ResumeFailureArgs)?

    @inlinable
    public convenience init(defaultResumeArgs: @escaping @autoclosure () -> ResumeArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void) where ResumeFailureArgs == Never {
        self.init(defaultResumeArgs: defaultResumeArgs, defaultResumeFailureArgs: nil, onResume: resumeFunction, onFailure: { _ in })
    }

    @inlinable
    public convenience init(defaultResumeArgs: @escaping @autoclosure () -> ResumeArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.init(defaultResumeArgs: defaultResumeArgs, defaultResumeFailureArgs: nil, onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    public convenience init(defaultResumeFailureArgs: @escaping @autoclosure () -> ResumeFailureArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void) where ResumeFailureArgs == Never {
        self.init(defaultResumeArgs: nil, defaultResumeFailureArgs: defaultResumeFailureArgs, onResume: resumeFunction, onFailure: { _ in })
    }

    @inlinable
    public convenience init(defaultResumeFailureArgs: @escaping @autoclosure () -> ResumeFailureArgs, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.init(defaultResumeArgs: nil, defaultResumeFailureArgs: defaultResumeFailureArgs, onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @usableFromInline
    init(defaultResumeArgs: (() -> ResumeArgs)?, defaultResumeFailureArgs: (() -> ResumeFailureArgs)?, onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        assert(defaultResumeArgs != nil || defaultResumeFailureArgs != nil, "\(#fileID) is inconsistent and is missing both default argument functions when one must be provided")
        self.defaultResumeArgs = defaultResumeArgs
        self.defaultResumeFailureArgs = defaultResumeFailureArgs
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        if let defaultResumeArgs = defaultResumeArgs {
            resume(args: defaultResumeArgs())
        } else if let defaultResumeFailureArgs = defaultResumeFailureArgs {
            resumeFailure(args: defaultResumeFailureArgs())
        } else {
            assertionFailure("\(#fileID) couldn't generate a default value to guarantee continuation because both input functions were nil")
        }
    }
}
