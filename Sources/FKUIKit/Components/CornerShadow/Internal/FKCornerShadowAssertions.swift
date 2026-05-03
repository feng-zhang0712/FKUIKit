//
// FKCornerShadowAssertions.swift
//

import Foundation

@inline(__always)
func fk_cornerShadowAssertMainThread() {
  dispatchPrecondition(condition: .onQueue(.main))
}
