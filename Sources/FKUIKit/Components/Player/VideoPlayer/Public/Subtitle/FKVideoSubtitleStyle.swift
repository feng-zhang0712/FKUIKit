import UIKit

/// Appearance of rendered external subtitles.
public struct FKVideoSubtitleStyle: Sendable, Equatable {
  public var fontSize: CGFloat
  public var textColorHex: UInt32
  public var backgroundColorHex: UInt32
  public var backgroundAlpha: CGFloat
  public var bottomInset: CGFloat

  public init(
    fontSize: CGFloat = 16,
    textColorHex: UInt32 = 0xFFFFFF,
    backgroundColorHex: UInt32 = 0x000000,
    backgroundAlpha: CGFloat = 0.55,
    bottomInset: CGFloat = 72
  ) {
    self.fontSize = fontSize
    self.textColorHex = textColorHex
    self.backgroundColorHex = backgroundColorHex
    self.backgroundAlpha = backgroundAlpha
    self.bottomInset = bottomInset
  }

  public static let `default` = FKVideoSubtitleStyle()
}

extension FKVideoSubtitleStyle {

  @MainActor
  public func textColor() -> UIColor {
    UIColor(
      red: CGFloat((textColorHex >> 16) & 0xFF) / 255,
      green: CGFloat((textColorHex >> 8) & 0xFF) / 255,
      blue: CGFloat(textColorHex & 0xFF) / 255,
      alpha: 1
    )
  }

  @MainActor
  public func backgroundColor() -> UIColor {
    UIColor(
      red: CGFloat((backgroundColorHex >> 16) & 0xFF) / 255,
      green: CGFloat((backgroundColorHex >> 8) & 0xFF) / 255,
      blue: CGFloat(backgroundColorHex & 0xFF) / 255,
      alpha: backgroundAlpha
    )
  }
}
