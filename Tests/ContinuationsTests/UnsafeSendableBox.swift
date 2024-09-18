//
//  UnsafeSendableBox.swift
//  Continuations
//
//  Created by Braden Scothern on 9/18/24.
//  Copyright © 2020-2024 Braden Scothern. All rights reserved.
//

import Atomics

@propertyWrapper
public final class UnsafeSendableBox<Value>: @unchecked Sendable where Value: AtomicValue {
    public var _wrappedValue: UnsafeAtomic<Value>
    public var wrappedValue: Value {
        get { _wrappedValue.load(ordering: .sequentiallyConsistent) }
        set { _wrappedValue.store(newValue, ordering: .sequentiallyConsistent) }
        _modify {
            // This is NOT safe and doesn't actually protect things properly. It opens up things to race conditions but makes tests go faster.
            // Do NOT use this type in real code outside of testing
            var value = _wrappedValue.load(ordering: .acquiring)
            defer {
                _wrappedValue.store(value, ordering: .releasing)
            }
            yield &value
        }
    }

    public var projectedValue: UnsafeSendableBox<Value> {
        self
    }

    public init(wrappedValue: Value) {
        self._wrappedValue = .create(wrappedValue)
    }
}
