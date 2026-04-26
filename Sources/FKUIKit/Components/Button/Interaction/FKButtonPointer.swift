import UIKit

/// Pointer interaction configuration for iPadOS/macOS Catalyst.
public struct FKButtonPointerConfiguration: Sendable {
  /// Enables pointer interaction when available.
  public var isEnabled: Bool
  /// When enabled, applies a subtle hover highlight by animating alpha.
  public var showsHoverHighlight: Bool
  /// Hover alpha multiplier applied on top of current alpha.
  public var hoverAlphaMultiplier: CGFloat

  public init(
    isEnabled: Bool = false,
    showsHoverHighlight: Bool = true,
    hoverAlphaMultiplier: CGFloat = 0.96
  ) {
    self.isEnabled = isEnabled
    self.showsHoverHighlight = showsHoverHighlight
    self.hoverAlphaMultiplier = max(0, min(1, hoverAlphaMultiplier))
  }
}

