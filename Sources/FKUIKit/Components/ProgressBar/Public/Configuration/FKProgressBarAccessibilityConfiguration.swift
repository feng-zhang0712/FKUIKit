import UIKit

/// VoiceOver label and hint overrides, and the “frequent updates” trait for ``FKProgressBar``.
public struct FKProgressBarAccessibilityConfiguration: Sendable {
  /// When non-empty, overrides the default `accessibilityLabel`.
  public var customLabel: String?
  /// When non-empty, sets `accessibilityHint`.
  public var customHint: String?
  /// When `true`, includes ``UIAccessibilityTraits/updatesFrequently`` while indeterminate or animating.
  public var treatAsFrequentUpdates: Bool

  public init(
    customLabel: String? = nil,
    customHint: String? = nil,
    treatAsFrequentUpdates: Bool = true
  ) {
    self.customLabel = customLabel
    self.customHint = customHint
    self.treatAsFrequentUpdates = treatAsFrequentUpdates
  }
}
