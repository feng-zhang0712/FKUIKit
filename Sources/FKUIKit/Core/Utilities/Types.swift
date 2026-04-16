//
// Types.swift
//
// Shared closure typealiases across components to reduce repetition.
//

import Foundation

/// A callback with no parameters and no return value (completion, tap handling, etc.).
public typealias VoidHandler = () -> Void
/// A single-value callback.
public typealias ValueHandler<Value> = (Value) -> Void
/// An optional single-value callback for cases where the value may be nil.
public typealias OptionalValueHandler<Value> = (Value?) -> Void
/// Error callback (passes only the failure reason).
public typealias ErrorHandler = (Error) -> Void
/// Result callback carrying either a success value or a failure error.
public typealias ResultHandler<Value> = (Result<Value, Error>) -> Void
