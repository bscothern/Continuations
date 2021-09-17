//
//  TestSupport.swift
//  Continuations
//
//  Created by Braden Scothern on 10/20/20.
//  Copyright © 2020-2021 Braden Scothern. All rights reserved.
//

#if DEBUG
/// A scope for variables that helps enable testing.
///
/// These flags are used to disable assertions while helping ensure correct behavior for normal use.
@usableFromInline
enum _TestSupport {
    @usableFromInline
    static var assertCondition: Bool { !_triggerAssertions }

    @usableFromInline
    static var _triggerAssertions = true

    static func disableAssertions() {
        _triggerAssertions = false
    }

    static func enableAssertions() {
        _triggerAssertions = true
    }
}
#endif
