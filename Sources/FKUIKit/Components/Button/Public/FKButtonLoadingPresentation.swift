import UIKit

/// Loading chrome: dim content behind a spinner, or replace content with spinner + optional message.
public enum FKButtonLoadingPresentation {
  /// Shows indicator above dimmed content.
  case overlay(dimmedContentAlpha: CGFloat)
  /// Replaces content with indicator and optional text.
  case replacesContent(FKButtonLoadingReplacementOptions)
}

/// Message and spacing options for replacement loading mode.
public struct FKButtonLoadingReplacementOptions {
  public var spacingAfterIndicator: CGFloat
  public var message: String?
  public var messageFont: UIFont
  public var messageColor: UIColor

  /// Creates replacement loading options.
  public init(
    spacingAfterIndicator: CGFloat = 8,
    message: String? = nil,
    messageFont: UIFont = .preferredFont(forTextStyle: .subheadline),
    messageColor: UIColor = .label
  ) {
    self.spacingAfterIndicator = spacingAfterIndicator
    self.message = message
    self.messageFont = messageFont
    self.messageColor = messageColor
  }
}
