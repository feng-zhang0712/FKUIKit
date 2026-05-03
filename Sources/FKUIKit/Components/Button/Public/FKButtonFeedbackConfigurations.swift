import AudioToolbox
import Foundation
import UIKit

// MARK: - Haptics

/// Haptic feedback options for `FKButton` (UIKit `UIImpactFeedbackGenerator`).
public struct FKButtonHapticsConfiguration: Sendable {
  /// When `true`, triggers impact feedback when the button enters the highlighted state.
  public var onPressDown: Bool
  /// When `true`, triggers impact feedback when a primary action fires (`touchUpInside` / `primaryActionTriggered`).
  public var onPrimaryAction: Bool
  /// Style passed to `UIImpactFeedbackGenerator`.
  public var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle

  public init(
    onPressDown: Bool = false,
    onPrimaryAction: Bool = false,
    impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
  ) {
    self.onPressDown = onPressDown
    self.onPrimaryAction = onPrimaryAction
    self.impactStyle = impactStyle
  }
}

// MARK: - Sound

/// Optional AudioServices-based sound feedback for `FKButton`.
public struct FKButtonSoundFeedbackConfiguration: Sendable {
  /// Sound source for `AudioServicesPlaySystemSound`.
  public enum Sound: Sendable, Equatable {
    /// Built-in system sound identifier.
    case system(SystemSoundID)
    /// Local file URL registered with `AudioServicesCreateSystemSoundID`.
    ///
    /// Use short bundled assets; dispose is handled by `FKButton` when the URL changes.
    case customFileURL(URL)
  }

  public var onPressDown: Bool
  public var onPrimaryAction: Bool
  public var pressDownSound: Sound
  public var primaryActionSound: Sound

  /// Defaults keep feedback off so global adoption does not change behavior.
  public init(
    onPressDown: Bool = false,
    onPrimaryAction: Bool = false,
    pressDownSound: Sound = .system(1104),
    primaryActionSound: Sound = .system(1104)
  ) {
    self.onPressDown = onPressDown
    self.onPrimaryAction = onPrimaryAction
    self.pressDownSound = pressDownSound
    self.primaryActionSound = primaryActionSound
  }
}

// MARK: - Pointer (iPadOS / Mac Catalyst)

/// Pointer (mouse/trackpad) hover behavior when `UIPointerInteraction` is available.
public struct FKButtonPointerConfiguration: Sendable {
  public var isEnabled: Bool
  /// When `true`, hover applies `hoverAlphaMultiplier` on top of the resolved opacity.
  public var showsHoverHighlight: Bool
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
