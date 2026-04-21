//
//  FKButton+LoadingPresentation.swift
//
//  Controls how the activity indicator is shown while `isLoading == true`.
//

import UIKit

// MARK: - Loading presentation

public extension FKButton {

  /// Visual treatment for the built-in loading state (`setLoading(_:presentation:)` / `performWhileLoading`).
  enum LoadingPresentationStyle {
    /// Activity indicator centered on top of the normal content stack, which is dimmed with alpha.
    /// This matches the classic “spinner over button” look.
    case overlay(dimmedContentAlpha: CGFloat)

    /// Hides the title / image / custom stack entirely and shows a centered row:
    /// `[UIActivityIndicatorView][optional status label]`.
    /// Use the message for copy such as “处理中…”.
    case replacesContent(ReplacedContentLoadingOptions)
  }

  // MARK: ReplacedContentLoadingOptions

  /// Options for `.replacesContent` loading style.
  struct ReplacedContentLoadingOptions {
    /// Horizontal space between the spinner and the status label.
    public var spacingAfterIndicator: CGFloat
    /// Shown to the right of the spinner; `nil` or empty hides the label.
    public var message: String?
    public var messageFont: UIFont
    public var messageColor: UIColor

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
}
