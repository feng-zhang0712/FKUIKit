//
// FKStarRating+Chaining.swift
//
// Fluent configuration helpers for FKStarRating.
//

import UIKit

public extension FKStarRating {
  /// Sets rating mode in a fluent style.
  @discardableResult
  func withMode(_ mode: FKStarRatingMode) -> Self {
    configure { $0.mode = mode }
    return self
  }

  /// Sets star count in a fluent style.
  @discardableResult
  func withStarCount(_ starCount: Int) -> Self {
    configure { $0.starCount = starCount }
    return self
  }

  /// Sets min/max rating range in a fluent style.
  @discardableResult
  func withRange(min: CGFloat, max: CGFloat) -> Self {
    configure {
      $0.minimumRating = min
      $0.maximumRating = max
    }
    return self
  }

  /// Sets editability in a fluent style.
  @discardableResult
  func withEditable(_ isEditable: Bool) -> Self {
    configure { $0.isEditable = isEditable }
    return self
  }

  /// Sets rendering mode with selected/unselected colors.
  @discardableResult
  func withColors(selected: UIColor, unselected: UIColor) -> Self {
    configure {
      $0.renderMode = .color
      $0.selectedColor = selected
      $0.unselectedColor = unselected
    }
    return self
  }

  /// Sets image rendering resources.
  @discardableResult
  func withImages(selected: UIImage?, unselected: UIImage?, half: UIImage? = nil) -> Self {
    configure {
      $0.renderMode = .image
      $0.selectedImage = selected
      $0.unselectedImage = unselected
      $0.halfImage = half
    }
    return self
  }
}
