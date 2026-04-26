import AudioToolbox
import Foundation

/// Sound feedback configuration for `FKButton`.
public struct FKButtonSoundFeedbackConfiguration: Sendable {
  /// Sound source definition.
  public enum Sound: Sendable, Equatable {
    /// A built-in system sound identifier.
    case system(SystemSoundID)
    /// A local file URL used to create a `SystemSoundID`.
    ///
    /// - Important: The URL should point to a short, local audio file bundled with the app.
    case customFileURL(URL)
  }

  /// Plays sound when the button enters highlighted state.
  public var onPressDown: Bool
  /// Plays sound when a primary action is triggered.
  public var onPrimaryAction: Bool
  /// Sound used for press-down feedback.
  public var pressDownSound: Sound
  /// Sound used for primary-action feedback.
  public var primaryActionSound: Sound

  /// Creates a sound-feedback configuration.
  ///
  /// - Note: Defaults are intentionally disabled to avoid changing existing button behavior.
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
