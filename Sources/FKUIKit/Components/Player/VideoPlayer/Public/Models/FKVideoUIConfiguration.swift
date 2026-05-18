import UIKit

/// Visual theme for video chrome.
public enum FKVideoPlayerTheme: Sendable, Equatable {
  case automatic
  case light
  case dark
}

/// UI behavior and chrome for ``FKVideoPlayerView``.
public struct FKVideoUIConfiguration: Sendable, Equatable {
  public var theme: FKVideoPlayerTheme
  public var controlsAutoHideInterval: TimeInterval
  public var showsRemainingTime: Bool
  public var gestureSeekSeconds: TimeInterval
  public var allowsPictureInPicture: Bool
  public var allowsAirPlay: Bool
  public var aspectFill: Bool
  public var tintColorHex: UInt32?

  public init(
    theme: FKVideoPlayerTheme = .automatic,
    controlsAutoHideInterval: TimeInterval = 5.0,
    showsRemainingTime: Bool = false,
    gestureSeekSeconds: TimeInterval = 10.0,
    allowsPictureInPicture: Bool = true,
    allowsAirPlay: Bool = true,
    aspectFill: Bool = false,
    tintColorHex: UInt32? = nil
  ) {
    self.theme = theme
    self.controlsAutoHideInterval = controlsAutoHideInterval
    self.showsRemainingTime = showsRemainingTime
    self.gestureSeekSeconds = gestureSeekSeconds
    self.allowsPictureInPicture = allowsPictureInPicture
    self.allowsAirPlay = allowsAirPlay
    self.aspectFill = aspectFill
    self.tintColorHex = tintColorHex
  }

  public static let `default` = FKVideoUIConfiguration()
}

extension FKVideoUIConfiguration {

  @MainActor
  public func resolvedTintColor(traitCollection: UITraitCollection) -> UIColor {
    if let tintColorHex {
      return UIColor(
        red: CGFloat((tintColorHex >> 16) & 0xFF) / 255,
        green: CGFloat((tintColorHex >> 8) & 0xFF) / 255,
        blue: CGFloat(tintColorHex & 0xFF) / 255,
        alpha: 1
      )
    }
    switch theme {
    case .light:
      return .systemBlue
    case .dark:
      return .white
    case .automatic:
      return traitCollection.userInterfaceStyle == .dark ? .white : .systemBlue
    }
  }
}
