# Continuations

A simple library for efficient [continuations](https://en.wikipedia.org/wiki/Continuation) including ones that are guaranteed to be executed.

![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)
![Swift Versions](https://img.shields.io/badge/Swift-5.3+-orange.svg)

Continuations are an alternative to traditional callbacks to help with asynchronous operations.
As provided in this library they are resumed with whatever arguments they require and you know if it was a success or failure right away.
This style takes heavy influence from Swift's `Result` type.

Because continuations are particularly useful for tasks that can't do work until after receiving user input there are 2 variations that ensure they are eventually called with a default value for success or failure.

## Relationship to Swift 5.5's Concurrency
The continuation types in this library have been designed to be nearly identical in usage to both `UnsafeContinuation` and `CheckedContinuation`.
This makes it so you things can more easily be migrated to Swift's async/await when you are able to support the minimum deployment target required for those features.

The biggest difference is that Swift's continuations properly throw an error at the suspension point when things go wrong.
Because this library can't do that since things aren't being suspended there are 2 ways to resume a failure.
When you want to pass a non-Error type back as part of the failure then you can call `resumeFailure(returning:)`.
When your failure input does conform to Error then you can call `resume(throwing:)` in order to minimize code changes in the future when your code moves to Swift's async/await.

## Why use continuations over other async patterns
When working in Swift (especially for Apple platforms) we often work with delegate relationships.
When we need to asynchronously work with a delegate things instantly get much more complex.

For example you can document that you will call a function and then the delegate is responsible to call you back with some set of functions.
This has the downside of it is easy to forget to call one of those functions that lets you resume your operation.
So you may end up in a broken state or hold onto resources you don't need.

Because of those downsides you might decide that it is better to pass a callback to the delegate.
This is generally better but you still have the issue of that the delegate might not call it.
How long do you wait?
You have no way to know if the callback has gone out of scope.
Perhaps the delegate had to go make some networking requests and won't be able to resume the operation for a while.
So you have to once again sit in a broken state or hold onto resources you don't need.

This is where Continuations shine.
You now have a way to know if the delegate still has a reference to your `Continuation` because if you keep a `weak` reference to it you know when it has gone out of scope.
Less lets you do more to clean up state rather than enter a failure state.

If you don't even want to keep track of it with `weak` you can use one of the 2 variations that is guaranteed to execute with the provided default arguments like in the example below.

```swift
import Continuations

// Some operation that need to suspend
let continuation = GuaranteeFailureContinuation<Data, Void>(defaultResumeFailureValue: ()) { data in
    // Process data and continue running the operation
} onFailure: {
    // Clean up operation
}

delegate.requestData(with: continuation)

// In the delegate
func requestData(with continuation: Continuation<Data, Void>) {
    guard someCondition {
        continuation.resumeFailure()
        return
    }
    continuation.resume(returning: self.someData)
}
```

While this is a very simple example it has ensured that we will be able to continue the operation we were performing.
If that is that we continue down the happy path because we have good `Data` or if we just clean up it doesn't matter.
We know that we will get back into a valid state.

So we know that if we are in an invalid state at any point then we have a `Continuation` out in the wild that hasn't been fired yet.
Perhaps it is appropriate to just clean up things in that case.
Perhaps it is appropriate to throw an error or return `nil`.
Continuations just makes it much easier to reason and safely write asynchronous relationships between objects.

## Types of continuations
The three types provided are
* `UncheckedContinuation<ResumeValue, ResumeFailureValue>` - This is the most basic and simply ties together successful and failure closures so things can be resumed.
* `Continuation<ResumeValue, ResumeFailureValue>` - This ensures that a resume function is only called once and raises an assertion in debug modes if more than one is raised.
* `GuaranteeFailureContinuation<ResumeValue, ResumeFailureValue>` - This ensures that when it goes out of scope the failure case is resumed if it was not resumed before that point.
* `GuaranteeResumeContinuation<ResumeValue, ResumeFailureValue>` - This ensures that when it goes out of scope that the success case is resumed if it was not resumed before that point.

These are all generic so you can customize the inputs to each function easily while having consistency.
If you need to pass a more complex set of values as `ResumeValue` or `ResumeFailureValue` it is recommended that you use a concrete type or typealias so things can be better documented.

## Adding `Continuations` as a dependency
Add the following line to your package dependencies in your `Package.swift` file:
```swift
.package(url: "https://github.com/bscothern/Continuations", .upToNextMinor(from: "0.3.0")),
```

## Continuation Structure
```
                    ┌───────────────────────┐
                    │                       │
                    │ UncheckedContinuation │
                    │                       │
                    └───────────────────────┘
                                ▲
                                │
                                │
                        ┌───────┴──────┐
                        │              │
                        │ Continuation │
                        │              │
                        └──────────────┘
                           ▲        ▲
                ┌──────────┘        └───────┐
                │                           │
┌───────────────┴─────────────┐  ┌──────────┴───────────────────┐
│                             │  │                              │
│ GuaranteeResumeContinuation │  │ GuaranteeFailureContinuation │
│                             │  │                              │
└─────────────────────────────┘  └──────────────────────────────┘
```
