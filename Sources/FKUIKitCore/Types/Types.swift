//
// Types.swift
//
// 组件间共用的闭包类型别名，减少重复书写。
//

import Foundation

/// 无参数、无返回值回调：用于完成通知、点击事件等场景。
public typealias VoidHandler = () -> Void
/// 单值回调：用于把一个确定值抛给外部。
public typealias ValueHandler<Value> = (Value) -> Void
/// 可空单值回调：用于值可能不存在（nil）的异步/事件场景。
public typealias OptionalValueHandler<Value> = (Value?) -> Void
/// 错误回调：仅传递失败原因。
public typealias ErrorHandler = (Error) -> Void
/// 结果回调：统一承载成功值或失败错误。
public typealias ResultHandler<Value> = (Result<Value, Error>) -> Void
