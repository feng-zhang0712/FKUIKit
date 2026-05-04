import UIKit

/// Typography and chevron layout for a tab in ``FKFilterTab``.
public struct FKFilterStripMetrics: Sendable {
  public var titleTextStyle: UIFont.TextStyle
  public var subtitleTextStyle: UIFont.TextStyle
  public var chevronSize: CGSize
  public var chevronSpacing: CGFloat
  public var titleSubtitleSpacing: CGFloat

  public init(
    titleTextStyle: UIFont.TextStyle = .subheadline,
    subtitleTextStyle: UIFont.TextStyle = .caption2,
    chevronSize: CGSize = CGSize(width: 14, height: 14),
    chevronSpacing: CGFloat = 4,
    titleSubtitleSpacing: CGFloat = 2
  ) {
    self.titleTextStyle = titleTextStyle
    self.subtitleTextStyle = subtitleTextStyle
    self.chevronSize = chevronSize
    self.chevronSpacing = chevronSpacing
    self.titleSubtitleSpacing = titleSubtitleSpacing
  }
}
