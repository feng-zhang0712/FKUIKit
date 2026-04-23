import Foundation

/// Localizable strings used by `FKTextField`.
///
/// Consumers can replace defaults globally or per-instance to align with product copywriting
/// and localization systems without forking the component.
public struct FKTextFieldLocalization: Sendable, Equatable {
  /// Accessibility label for clear button.
  public var clearButtonLabel: String
  /// Accessibility label for password toggle while hidden.
  public var passwordHiddenLabel: String
  /// Accessibility label for password toggle while visible.
  public var passwordVisibleLabel: String
  /// Prefix used for counter accessibility announcement.
  public var counterAnnouncementPrefix: String
  /// Prefix used for error accessibility announcement.
  public var errorAnnouncementPrefix: String
  /// Prefix used for success accessibility announcement.
  public var successAnnouncementPrefix: String

  /// Creates a localization bundle.
  public init(
    clearButtonLabel: String = "Clear text",
    passwordHiddenLabel: String = "Show password",
    passwordVisibleLabel: String = "Hide password",
    counterAnnouncementPrefix: String = "Character count",
    errorAnnouncementPrefix: String = "Error",
    successAnnouncementPrefix: String = "Success"
  ) {
    self.clearButtonLabel = clearButtonLabel
    self.passwordHiddenLabel = passwordHiddenLabel
    self.passwordVisibleLabel = passwordVisibleLabel
    self.counterAnnouncementPrefix = counterAnnouncementPrefix
    self.errorAnnouncementPrefix = errorAnnouncementPrefix
    self.successAnnouncementPrefix = successAnnouncementPrefix
  }
}

