import Foundation

/// Semantic role for an action slot in `FKEmptyStateView`.
///
/// The renderer intentionally maps slots (`primary/secondary/tertiary`) to visual styles.
/// `kind` communicates product intent for analytics and business rules, while slot position
/// controls appearance to keep backward compatibility with older one-button integrations.
///
/// - Tip: Route user interactions by `FKEmptyStateAction.id` (stable key) and treat `kind` as a
///   presentation hint (primary/secondary/tertiary).
public enum FKEmptyStateActionKind: String, CaseIterable, Equatable, Sendable {
  case primary
  case secondary
  case tertiary
  case link
}

/// Immutable-friendly action payload rendered by EmptyState.
///
/// - Important: `id` should stay stable across releases because events are emitted by id.
/// - Note: `isLoading` currently disables interaction but does not show a spinner by itself;
///   callers decide the loading affordance in copy or host UI.
/// - Note: `payload` is an optional string dictionary intended for analytics / routing metadata.
///   Keep it small (avoid large blobs) because it may be transported through NotificationCenter.
public struct FKEmptyStateAction: Equatable, Sendable {
  public var id: String
  public var title: String
  public var kind: FKEmptyStateActionKind
  public var isEnabled: Bool
  public var isLoading: Bool
  public var payload: [String: String]

  public init(
    id: String,
    title: String,
    kind: FKEmptyStateActionKind,
    isEnabled: Bool = true,
    isLoading: Bool = false,
    payload: [String: String] = [:]
  ) {
    self.id = id
    self.title = title
    self.kind = kind
    self.isEnabled = isEnabled
    self.isLoading = isLoading
    self.payload = payload
  }
}

/// Fixed-size action container used by UIKit rendering.
///
/// The set is intentionally capped at three actions to preserve predictable hierarchy
/// and avoid overflow complexity in compact layouts.
public struct FKEmptyStateActionSet: Equatable, Sendable {
  public var primary: FKEmptyStateAction?
  public var secondary: FKEmptyStateAction?
  public var tertiary: FKEmptyStateAction?

  public init(
    primary: FKEmptyStateAction? = nil,
    secondary: FKEmptyStateAction? = nil,
    tertiary: FKEmptyStateAction? = nil
  ) {
    self.primary = primary
    self.secondary = secondary
    self.tertiary = tertiary
  }

  /// Returns actions in rendering priority order.
  ///
  /// Keep this order stable so analytics and UI tests can reason about index-based snapshots.
  public var all: [FKEmptyStateAction] {
    [primary, secondary, tertiary].compactMap { $0 }
  }
}
