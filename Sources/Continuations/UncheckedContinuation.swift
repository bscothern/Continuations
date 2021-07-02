//
//  UncheckedContinuation.swift
//  Continuations
//
//  Created by Braden Scothern on 7/1/21.
//  Copyright © 2020-2021 Braden Scothern. All rights reserved.
//

/// A continuation is a context that should be resumed or failed in the future to continue running some asynchronous operation.
///
/// Unlike when a callback is executed when a continuation has its success or failure known right away.
public class UncheckedContinuation<ResumeValue, ResumeFailure> {
    @usableFromInline
    let resumeFunction: (_ value: ResumeValue) -> Void
    @usableFromInline
    let resumeFailureFunction: (_ failure: ResumeFailure) -> Void

    /// Creates a `Continuation`.
    ///
    /// - Parameters:
    ///   - resumeFunction: The function that will be called when `resume(returning:)` is called.
    ///   - resumeFailureFunction: The function that will be called when `resumeFailure(returning:)` is called.
    ///   - value: The arguments to the resume function being executed.
    @inlinable
    public init(
        onResume resumeFunction: @escaping (_ value: ResumeValue) -> Void,
        onFailure resumeFailureFunction: @escaping (_ value: ResumeFailure) -> Void
    ) {
        self.resumeFunction = resumeFunction
        self.resumeFailureFunction = resumeFailureFunction
    }

    /// Has the continuation resume its operation in a successful manner.
    ///
    /// - Parameter value: The arguments to pass to this continuations resume function.
    @inlinable
    public func resume(returning value: ResumeValue) {
        resumeFunction(value)
    }

    /// Has the continuation resume its operation in a failed manner.
    ///
    /// - Parameter value: The arguments to pass to this continuations resume failed function.
    @inlinable
    @available(*, deprecated, message: "Continuations that have a ResumeFailure that conforms to Error should use the function resume(throwing:) in order to match Swift 5.5 concurrency.")
    public func resumeFailure(returning value: ResumeFailure) where ResumeFailure: Error {
        resumeFailureFunction(value)
    }

    /// Has the continuation resume its operation in a failed manner.
    ///
    /// - Parameter value: The arguments to pass to this continuations resume failed function.
    @inlinable
    public func resumeFailure(returning value: ResumeFailure) {
        resumeFailureFunction(value)
    }

    /// Has the continuation resume its operation in a failed manner.
    ///
    /// - Note: While this doesn't actually throw it is named
    ///
    /// - Parameter error: The arguments to pass to this continuations resume failed function.
    @inlinable
    public func resume(throwing error: ResumeFailure)
    where ResumeFailure: Error {
        resumeFailureFunction(error)
    }

    /// Has the continuation resume its operation either normally or by raising a failure according to the given `Result` value.
    ///
    /// - Parameter result: A value to either resume with normally or to raise as a failure.
    @inlinable
    public func resume(with result: Result<ResumeValue, ResumeFailure>)
    where ResumeFailure: Error {
        switch result {
        case let .success(value):
            resumeFunction(value)
        case let .failure(error):
            resumeFailureFunction(error)
        }
    }
}

extension UncheckedContinuation where ResumeValue == Void {
    /// Has the continuation resume its operation in a successful manner.
    @_transparent
    public func resume() {
        resume(returning: Void())
    }
}

extension UncheckedContinuation where ResumeFailure == Void {
    /// Has the continuation resume its operation in a failed manner.
    @_transparent
    public func resumeFailure() {
        resumeFailure(returning: Void())
    }
}
