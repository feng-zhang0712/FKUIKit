//
// FKStickyConfiguration.swift
//

import UIKit

/// Runtime configuration for sticky calculation.
public struct FKStickyConfiguration: Sendable {
  /// Additional top offset added to safe-area inset.
  public var additionalTopInset: CGFloat

  /// Whether to include `adjustedContentInset.top` when pinning.
  public var usesAdjustedContentInset: Bool

  /// Enable automatic safe-area adaptation.
  public var adaptsSafeArea: Bool

  /// Enables sticky processing.
  public var isEnabled: Bool

  /// Emits every scroll callback.
  public var onDidScroll: (@MainActor (_ scrollView: UIScrollView, _ effectiveOffsetY: CGFloat) -> Void)?

  /// Creates a configuration object.
  public init(
    additionalTopInset: CGFloat = 0,
    usesAdjustedContentInset: Bool = true,
    adaptsSafeArea: Bool = true,
    isEnabled: Bool = true,
    onDidScroll: (@MainActor (_ scrollView: UIScrollView, _ effectiveOffsetY: CGFloat) -> Void)? = nil
  ) {
    self.additionalTopInset = additionalTopInset
    self.usesAdjustedContentInset = usesAdjustedContentInset
    self.adaptsSafeArea = adaptsSafeArea
    self.isEnabled = isEnabled
    self.onDidScroll = onDidScroll
  }

  /// Default production configuration.
  public static let `default` = FKStickyConfiguration()
}
