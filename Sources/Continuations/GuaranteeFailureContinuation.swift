//
//  GuaranteeFailureContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2021 Braden Scothern. All rights reserved.
//

import Atomics

/// A `Continuation` that has the guarantee that `resumeFailure(value:)` will be called on deinit if it has not already been resumed.
///
/// If manually resumed more than once then nothing will happen in release mode and an assertion will be rasied in debug mode.
public final class GuaranteeFailureContinuation<ResumeValue, ResumeFailureValue>: Continuation<ResumeValue, ResumeFailureValue> {
    @usableFromInline
    let defaultResumeFailureValue: () -> ResumeFailureValue

    /// Creates a `GuaranteeFailureContinuation`.
    /// 
    /// - Parameters:
    ///   - defaultResumeFailureValue;;: An autoclosure that will be executed to supply argume;nts to `resumeFailure(returning:)` on deinit if the continuation has not already been resumed.
    ///   - resumeFunction: The function that will be called when `resume(returning:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resume(throwing:)` or `resumeFailure(returning:)` is called.
    ///   - value: The arguments to the resume function being executed.
    @inlinable
    public init(
        defaultResumeFailureValue: @escaping @autoclosure () -> ResumeFailureValue,
        onResume resumeFunction: @escaping (_ value: ResumeValue) -> Void,
        onFailure resumeFailureFunction: @escaping (_ value: ResumeFailureValue) -> Void
    ) {
        self.defaultResumeFailureValue = defaultResumeFailureValue
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }
    
    /// Creates a `GuaranteeFailureContinuation`.
    ///
    /// - Parameters:
    ///   - defaultResumeFailureValue;;: An autoclosure that will be executed to supply argume;nts to `resumeFailure(returning:)` on deinit if the continuation has not already been resumed.
    ///   - resumeFunction: The function that will be called when `resume(returning:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resume(throwing:)` or `resumeFailure(returning:)` is called.
    ///   - value: The arguments to the resume function being executed.
    @inlinable
    public init(
        defaultResumeFailureValue: @escaping @autoclosure () -> ResumeFailureValue = Void(),
        onResume resumeFunction: @escaping (_ value: ResumeValue) -> Void,
        onFailure resumeFailureFunction: @escaping (_ value: ResumeFailureValue) -> Void
    ) where ResumeFailureValue == Void {
        self.defaultResumeFailureValue = defaultResumeFailureValue
        super.init(onResume: resumeFunction, onFailure: resumeFailureFunction)
    }

    @inlinable
    deinit {
        guard !haveRun.load(ordering: .relaxed) else { return }
        resumeFailure(returning: defaultResumeFailureValue())
    }
}
