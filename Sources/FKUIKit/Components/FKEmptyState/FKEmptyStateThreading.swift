//
// FKEmptyStateThreading.swift
//
// Shared main-thread guard for empty-state UI entry points.
//

import Foundation

// MARK: - Main-thread assertion

/// Ensures empty-state APIs run on the main queue. Crashes in debug if violated.
func fk_emptyStateAssertMainThread(file: StaticString = #fileID, line: UInt = #line) {
  dispatchPrecondition(condition: .onQueue(.main))
}
