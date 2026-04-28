import UIKit

public extension FKPresentationConfiguration {
  /// Effects applied to the presenting view controller while content is shown.
  struct PresentingViewEffectConfiguration {
    /// Enables presenting-view effects.
    var isEnabled: Bool
    /// Scale applied to presenting view at peak presentation.
    var scale: CGFloat
    /// Optional blur style overlayed on presenting view.
    var blurStyle: UIBlurEffect.Style?
    /// Blur overlay alpha at peak presentation.
    var blurAlpha: CGFloat

    /// Creates presenting-view effects.
    ///
    /// - Important: When enabled, FK will apply transforms and an overlay blur view to the presenting view.
    ///   This is disabled by default to avoid surprising apps with custom container hierarchies.
    public init(
      isEnabled: Bool = false,
      scale: CGFloat = 0.97,
      blurStyle: UIBlurEffect.Style? = nil,
      blurAlpha: CGFloat = 0.2
    ) {
      self.isEnabled = isEnabled
      self.scale = min(max(scale, 0.85), 1)
      self.blurStyle = blurStyle
      self.blurAlpha = min(max(blurAlpha, 0), 1)
    }
  }
}

