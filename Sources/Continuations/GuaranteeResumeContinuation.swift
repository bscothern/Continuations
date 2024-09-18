//
//  GuaranteeResumeContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2024 Braden Scothern. All rights reserved.
//

import Atomics

/// A `Continuation` that has the guarantee that `resume(value:)` will be called on deinit if it has not already been resumed.
///
/// If manually resumed more than once then nothing will happen in release mode and an assertion will be rasied in debug mode.
public final class GuaranteeResumeContinuation<ResumeValue, ResumeFailureValue>: Continuation<ResumeValue, ResumeFailureValue>, @unchecked Sendable {
    @usableFromInline
    let defaultResumeValue: @Sendable () -> ResumeValue

    /// Creates a `GuaranteeResumeContinuation`.
    ///
    /// - Parameters:
    ///   - defaultResumeValue: An autoclosure that will be executed to supply arguments to `resume(returning:)` on deinit if the continuation has not already been resumed.
    ///   - resumeFunction: The function that will be called when `resume(returning:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resume(throwing:)` or `resumeFailure(returning:)` is called.
    ///   - value: The arguments to the resume function being executed.
    @inlinable
    public init(
        defaultResumeValue: @escaping @Sendable @autoclosure () -> ResumeValue,
        onResume resumeFunction: @escaping @Sendable (_ value: ResumeValue) -> Void,
        onFailure resumeFailureFunction: @escaping @Sendable (_ value: ResumeFailureValue) -> Void
    ) {
        self.defaultResumeValue = defaultResumeValue
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    /// Creates a `GuaranteeResumeContinuation`.
    ///
    /// - Parameters:
    ///   - defaultResumeValue: An autoclosure that will be executed to supply arguments to `resume(returning:)` on deinit if the continuation has not already been resumed.
    ///   - resumeFunction: The function that will be called when `resume(returning:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resume(throwing:)` or `resumeFailure(returning:)` is called.
    ///   - value: The arguments to the resume function being executed.
    @inlinable
    public init(
        defaultResumeValue: @escaping @Sendable @autoclosure () -> ResumeValue = Void(),
        onResume resumeFunction: @escaping @Sendable (_ value: ResumeValue) -> Void,
        onFailure resumeFailureFunction: @escaping @Sendable (_ value: ResumeFailureValue) -> Void
    ) where ResumeValue == Void {
        self.defaultResumeValue = defaultResumeValue
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        resume(returning: defaultResumeValue())
    }
}
