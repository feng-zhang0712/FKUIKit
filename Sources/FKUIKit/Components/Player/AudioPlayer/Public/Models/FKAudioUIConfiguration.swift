import UIKit

/// Visual theme for audio chrome.
public enum FKAudioPlayerTheme: Sendable, Equatable {
  case automatic
  case light
  case dark
}

/// UI behavior for audio views.
public struct FKAudioUIConfiguration: Sendable, Equatable {
  public var theme: FKAudioPlayerTheme
  public var showsMiniBarWhenDismissed: Bool
  public var tintColorHex: UInt32?

  public init(
    theme: FKAudioPlayerTheme = .automatic,
    showsMiniBarWhenDismissed: Bool = true,
    tintColorHex: UInt32? = nil
  ) {
    self.theme = theme
    self.showsMiniBarWhenDismissed = showsMiniBarWhenDismissed
    self.tintColorHex = tintColorHex
  }

  public static let `default` = FKAudioUIConfiguration()

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

extension FKAudioUIConfiguration {

  /// Default artwork when no cover URL is available (main-actor only).
  @MainActor
  public var defaultArtwork: UIImage? {
    UIImage(systemName: "music.note")
  }
}
