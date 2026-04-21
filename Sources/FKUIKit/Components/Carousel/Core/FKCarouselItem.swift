//
// FKCarouselItem.swift
//

import UIKit

/// Content model rendered by `FKCarousel`.
///
/// The enum decouples visual rendering from data source format so the carousel can host
/// image content and arbitrary view content in a unified pipeline.
public enum FKCarouselItem {
  /// Local image content.
  case image(UIImage)
  /// Remote image content.
  case url(URL)
  /// Arbitrary custom view content.
  ///
  /// Prefer `customViewProvider` when infinite loop is enabled.
  case customView(UIView)
  /// Custom view factory called for each cell render.
  case customViewProvider(() -> UIView)
}
