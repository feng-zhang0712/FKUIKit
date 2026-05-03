#if canImport(UIKit)
import UIKit

public extension UIFont {
  /// Same font with a new `pointSize`.
  func fk_withSize(_ pointSize: CGFloat) -> UIFont {
    withSize(pointSize)
  }

  /// Returns a version of the receiver scaled for Dynamic Type using `UIFontMetrics`.
  @available(iOS 11.0, *)
  func fk_scaled(forTextStyle style: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
    UIFontMetrics(forTextStyle: style).scaledFont(for: self, compatibleWith: traitCollection)
  }

  /// Applies `UIFontDescriptor.SymbolicTraits.traitBold` when possible.
  func fk_bolded() -> UIFont {
    let traits = fontDescriptor.symbolicTraits.union(.traitBold)
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
    return UIFont(descriptor: descriptor, size: pointSize)
  }

  /// Applies `UIFontDescriptor.SymbolicTraits.traitItalic` when possible.
  func fk_italicized() -> UIFont {
    let traits = fontDescriptor.symbolicTraits.union(.traitItalic)
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}

#endif
