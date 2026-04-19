//
// Types.swift
//
// Shared closure typealiases across components to reduce repetition.
//

import Foundation

/// A callback with no parameters and no return value (completion, tap handling, etc.).
public typealias FKVoidHandler = () -> Void
/// A single-value callback.
public typealias FKValueHandler<Value> = (Value) -> Void
/// An optional single-value callback for cases where the value may be nil.
public typealias FKOptionalValueHandler<Value> = (Value?) -> Void
/// Error callback (passes only the failure reason).
public typealias FKErrorHandler = (Error) -> Void
/// Result callback carrying either a success value or a failure error.
public typealias FKResultHandler<Value> = (Result<Value, Error>) -> Void
