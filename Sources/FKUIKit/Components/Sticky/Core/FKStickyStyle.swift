//
// FKStickyStyle.swift
//

import UIKit

/// Visual state applied to a sticky target.
public enum FKStickyStyle: Sendable {
  /// Normal scroll-following state.
  case normal
  /// Sticky state pinned to configured top inset.
  case sticky
}
