import UIKit

public extension FKPresentationConfiguration {
  /// Backdrop rendering and behavior.
  struct BackdropConfiguration {
    /// Visual style to apply.
    public var style: FKBackdropStyle
    /// Whether tapping the backdrop dismisses content.
    public var allowsTapToDismiss: Bool

    /// Creates a backdrop configuration.
    ///
    /// - Note: Some styles (e.g. liquid glass) may downgrade depending on Reduce Transparency and Low Power Mode.
    public init(style: FKBackdropStyle = .dim(alpha: 0.35), allowsTapToDismiss: Bool = true) {
      self.style = style
      self.allowsTapToDismiss = allowsTapToDismiss
    }
  }
}

