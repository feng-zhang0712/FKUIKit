//
// FKRefreshConfiguration.swift
// FKUIKit — FKRefresh
//
// Tunables for thresholds, timing, colors, copy (`FKRefreshText`), silent refresh, and footer visibility.
//

import UIKit

/// Shared configuration for pull-to-refresh and load-more controls.
public struct FKRefreshConfiguration: Sendable {

  // MARK: - Thresholds & Timing

  /// Pull / overscroll distance required before a header/footer action arms.
  public var triggerThreshold: CGFloat

  /// Visual height of the embedded indicator container.
  public var expandedHeight: CGFloat

  /// Collapse animation duration after a terminal state.
  public var collapseDuration: TimeInterval

  /// How long `.finished` / `.listEmpty` / `.failed` stays visible before collapsing (header).
  public var finishedHoldDuration: TimeInterval

  /// If the work finishes faster than this interval, the loading state is held briefly to avoid a flash.
  public var minimumLoadingVisibilityDuration: TimeInterval

  // MARK: - Appearance

  /// Spinner / arrow tint for ``FKDefaultRefreshContentView``.
  public var tintColor: UIColor

  /// Container background (usually `.clear`).
  public var backgroundColor: UIColor

  /// Secondary label font size for bundled text.
  public var messageFontSize: CGFloat

  /// Secondary label weight for bundled text.
  public var messageFontWeight: UIFont.Weight

  /// Localizable / brand copy for the default content view.
  public var texts: FKRefreshText

  // MARK: - Behaviour

  /// Keeps the header expanded while `.refreshing` (classic pull-to-refresh).
  public var shouldKeepExpandedWhileRefreshing: Bool

  /// When `true`, programmatic / manual `beginRefreshing` does **not** reserve inset space and the
  /// control stays visually hidden — only `actionHandler` runs. End APIs still work.
  public var isSilentRefresh: Bool

  public var isHapticFeedbackEnabled: Bool

  /// Hides the load-more view when `contentSize` does not exceed the visible viewport height.
  public var autohidesFooterWhenNotScrollable: Bool

  /// Extra height added under the footer content to clear the home indicator / safe area.
  public var footerSafeAreaPadding: CGFloat

  // MARK: - Init

  public init(
    triggerThreshold: CGFloat = 64,
    expandedHeight: CGFloat = 64,
    collapseDuration: TimeInterval = 0.3,
    finishedHoldDuration: TimeInterval = 0.5,
    minimumLoadingVisibilityDuration: TimeInterval = 0.35,
    tintColor: UIColor = .secondaryLabel,
    backgroundColor: UIColor = .clear,
    messageFontSize: CGFloat = 12,
    messageFontWeight: UIFont.Weight = .regular,
    texts: FKRefreshText = .default,
    shouldKeepExpandedWhileRefreshing: Bool = true,
    isSilentRefresh: Bool = false,
    isHapticFeedbackEnabled: Bool = true,
    autohidesFooterWhenNotScrollable: Bool = true,
    footerSafeAreaPadding: CGFloat = 0
  ) {
    self.triggerThreshold = max(20, triggerThreshold)
    self.expandedHeight = max(20, expandedHeight)
    self.collapseDuration = max(0, collapseDuration)
    self.finishedHoldDuration = max(0, finishedHoldDuration)
    self.minimumLoadingVisibilityDuration = max(0, minimumLoadingVisibilityDuration)
    self.tintColor = tintColor
    self.backgroundColor = backgroundColor
    self.messageFontSize = max(8, messageFontSize)
    self.messageFontWeight = messageFontWeight
    self.texts = texts
    self.shouldKeepExpandedWhileRefreshing = shouldKeepExpandedWhileRefreshing
    self.isSilentRefresh = isSilentRefresh
    self.isHapticFeedbackEnabled = isHapticFeedbackEnabled
    self.autohidesFooterWhenNotScrollable = autohidesFooterWhenNotScrollable
    self.footerSafeAreaPadding = max(0, footerSafeAreaPadding)
  }

  public static let `default` = FKRefreshConfiguration()
}
