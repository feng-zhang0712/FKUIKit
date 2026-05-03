#if canImport(UIKit)
import UIKit

public extension UITraitCollection {
  /// `true` when the horizontal size class is `.compact`.
  var fk_isCompactHorizontal: Bool {
    horizontalSizeClass == .compact
  }

  /// `true` when the horizontal size class is `.regular`.
  var fk_isRegularHorizontal: Bool {
    horizontalSizeClass == .regular
  }

  /// `true` when the vertical size class is `.compact`.
  var fk_isCompactVertical: Bool {
    verticalSizeClass == .compact
  }

  /// `true` when the vertical size class is `.regular`.
  var fk_isRegularVertical: Bool {
    verticalSizeClass == .regular
  }

  /// Returns `true` when both collections report compatible traits for common layout decisions.
  func fk_hasSameHorizontalSizeClass(as other: UITraitCollection) -> Bool {
    horizontalSizeClass == other.horizontalSizeClass
  }
}

#endif
