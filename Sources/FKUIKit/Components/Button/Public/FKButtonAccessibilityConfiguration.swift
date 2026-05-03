import UIKit

/// VoiceOver overrides for `FKButton` when defaults (title → label, subtitle / loading → value) are not enough.
public struct FKButtonAccessibilityConfiguration: Sendable {
  /// Produces a label for the button.
  ///
  /// - Important: Return a stable meaning label (e.g. the title). Avoid returning ephemeral loading text here.
  public var labelProvider: (@Sendable (_ button: FKButton) -> String?)?

  /// Produces a value for the button.
  ///
  /// Recommended usage:
  /// - Put secondary information here (e.g. subtitle).
  /// - While loading, return progress text (e.g. "Loading" or a loading message).
  public var valueProvider: (@Sendable (_ button: FKButton) -> String?)?

  /// Produces a hint for the button.
  public var hintProvider: (@Sendable (_ button: FKButton) -> String?)?

  public init(
    labelProvider: (@Sendable (FKButton) -> String?)? = nil,
    valueProvider: (@Sendable (FKButton) -> String?)? = nil,
    hintProvider: (@Sendable (FKButton) -> String?)? = nil
  ) {
    self.labelProvider = labelProvider
    self.valueProvider = valueProvider
    self.hintProvider = hintProvider
  }
}

