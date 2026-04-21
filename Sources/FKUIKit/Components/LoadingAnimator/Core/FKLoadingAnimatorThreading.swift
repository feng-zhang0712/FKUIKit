//
// FKLoadingAnimatorThreading.swift
//

import Foundation

/// Executes a closure on the main thread.
///
/// This helper avoids duplicated thread checks in public APIs and animation lifecycle methods.
/// If already on the main thread the closure runs immediately; otherwise it is dispatched asynchronously.
@inline(__always)
func fk_loadingPerformOnMain(_ work: @escaping () -> Void) {
  if Thread.isMainThread {
    work()
  } else {
    DispatchQueue.main.async(execute: work)
  }
}

/// Asserts that the current execution context is the main queue.
///
/// - Parameters:
///   - file: File identifier used by debug diagnostics.
///   - line: Line number used by debug diagnostics.
///
/// Use this in synchronous APIs that must mutate UIKit or CoreAnimation state safely.
@inline(__always)
func fk_loadingAssertMainThread(
  file: StaticString = #fileID,
  line: UInt = #line
) {
  dispatchPrecondition(condition: .onQueue(.main))
}
