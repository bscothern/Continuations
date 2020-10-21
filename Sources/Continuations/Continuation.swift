//
//  Continuation.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020 Braden Scothern. All rights reserved.
//

import Atomics

public class Continuation<ResumeArgs, ResumeFailureArgs> {
    @usableFromInline
    let resumeFunction: (_ args: ResumeArgs) -> Void
    @usableFromInline
    let resumeFailureFunction: (_ args: ResumeFailureArgs) -> Void

    @usableFromInline
    var haveRun: UnsafeAtomic<Bool> = .create(false)

    @inlinable
    public convenience init(onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void) where ResumeFailureArgs == Never {
        self.init(onResume: resumeFunction, onFailure: { _ in })
    }

    @inlinable
    public init(onResume resumeFunction: @escaping (_ args: ResumeArgs) -> Void, onFailure resumeFailureFunction: @escaping (_ args: ResumeFailureArgs) -> Void) {
        self.resumeFunction = resumeFunction
        self.resumeFailureFunction = resumeFailureFunction
    }

    @inlinable
    deinit {
        haveRun.destroy()
    }

    @inlinable
    public func resume(args: ResumeArgs) {
        guard !haveRun.exchange(true, ordering: .releasing) else { return }
        resumeFunction(args)
    }

    @inlinable
    public func resumeFailure(args: ResumeFailureArgs) {
        guard !haveRun.exchange(true, ordering: .releasing) else { return }
        resumeFailureFunction(args)
    }
}

extension Continuation where ResumeArgs == Void {
    @_transparent
    public func resume() {
        resume(args: ())
    }
}

extension Continuation where ResumeFailureArgs == Void {
    @_transparent
    public func resumeFailure() {
        resumeFailure(args: ())
    }
}
