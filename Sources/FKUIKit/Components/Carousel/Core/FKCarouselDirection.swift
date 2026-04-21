//
// FKCarouselDirection.swift
//

import UIKit

/// Scroll direction used by `FKCarousel`.
public enum FKCarouselDirection: Sendable {
  /// Horizontal paging from left to right.
  case horizontal
  /// Vertical paging from top to bottom.
  case vertical

  /// Converts carousel-level direction to `UICollectionView` layout direction.
  ///
  /// This mapping keeps the public API independent from concrete layout implementation details.
  var collectionScrollDirection: UICollectionView.ScrollDirection {
    switch self {
    case .horizontal:
      return .horizontal
    case .vertical:
      return .vertical
    }
  }
}
