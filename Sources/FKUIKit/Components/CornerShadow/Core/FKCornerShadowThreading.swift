//
// FKCornerShadowThreading.swift
//
// Main-thread assertions for FKCornerShadow.
//

import Foundation

/// Verifies UIKit rendering operations happen on the main thread.
///
/// - Important: All FKCornerShadow public APIs eventually touch UIKit/CALayer state.
///   This precondition guards against accidental background-thread rendering updates.
@inline(__always)
func fk_cornerShadowAssertMainThread() {
  dispatchPrecondition(condition: .onQueue(.main))
}
