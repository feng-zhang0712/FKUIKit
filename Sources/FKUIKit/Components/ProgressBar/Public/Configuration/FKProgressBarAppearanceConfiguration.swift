import UIKit

/// Track, buffer, progress fills, borders, and fill style for ``FKProgressBar``.
///
/// - Note: Marked `@unchecked Sendable` because `UIColor` is not `Sendable`.
public struct FKProgressBarAppearanceConfiguration: @unchecked Sendable {
  public var trackColor: UIColor
  public var progressColor: UIColor
  /// Secondary fill (e.g. buffered stream) drawn behind progress when ``showsBuffer`` is `true`.
  public var bufferColor: UIColor

  public var trackBorderWidth: CGFloat
  public var trackBorderColor: UIColor
  public var progressBorderWidth: CGFloat
  public var progressBorderColor: UIColor

  public var fillStyle: FKProgressBarFillStyle
  public var progressGradientEndColor: UIColor

  public var showsBuffer: Bool

  public init(
    trackColor: UIColor = .tertiarySystemFill,
    progressColor: UIColor = .systemBlue,
    bufferColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.35),
    trackBorderWidth: CGFloat = 0,
    trackBorderColor: UIColor = .clear,
    progressBorderWidth: CGFloat = 0,
    progressBorderColor: UIColor = .clear,
    fillStyle: FKProgressBarFillStyle = .solid,
    progressGradientEndColor: UIColor = .systemTeal,
    showsBuffer: Bool = false
  ) {
    self.trackColor = trackColor
    self.progressColor = progressColor
    self.bufferColor = bufferColor
    self.trackBorderWidth = max(0, trackBorderWidth)
    self.trackBorderColor = trackBorderColor
    self.progressBorderWidth = max(0, progressBorderWidth)
    self.progressBorderColor = progressBorderColor
    self.fillStyle = fillStyle
    self.progressGradientEndColor = progressGradientEndColor
    self.showsBuffer = showsBuffer
  }
}
