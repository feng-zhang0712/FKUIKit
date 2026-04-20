import Foundation

/// Stable identifier used across the Filters module.
///
/// Why a wrapper instead of `String`?
/// - Avoids leaking backend IDs into UI code directly (stronger semantics than raw strings).
/// - Keeps models Hashable and easy to diff in UI layers.
/// - Allows future migration (e.g. numeric IDs) without changing public APIs.
public struct FKFilterID: Hashable, Sendable, RawRepresentable {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
}

/// Selection semantics for a section/panel.
///
/// Note:
/// - `FKFilterBarPresentation.BarItemModel.allowsMultipleSelection` is an additional gate.
/// - The effective mode is determined by the intersection of "panel allows multi" and "section requests multi".
public enum FKFilterSelectionMode: Sendable {
  case single
  case multiple
}

/// An option item (row / chip / grid pill) displayed in filter panels.
///
/// This is intentionally UI-friendly:
/// - `title` is presentation text
/// - `isSelected` drives selection UI state
/// - `isEnabled` allows disabling items without removing them
public struct FKFilterOptionItem: Hashable, Sendable {
  public let id: FKFilterID
  public var title: String
  public var subtitle: String?
  /// Rich text title used when present; plain `title` acts as fallback.
  public var attributedTitle: AttributedString?
  /// Rich text subtitle used when present; plain `subtitle` acts as fallback.
  public var attributedSubtitle: AttributedString?
  public var isSelected: Bool
  public var isEnabled: Bool

  public init(
    id: FKFilterID,
    title: String,
    subtitle: String? = nil,
    attributedTitle: AttributedString? = nil,
    attributedSubtitle: AttributedString? = nil,
    isSelected: Bool = false,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.attributedTitle = attributedTitle
    self.attributedSubtitle = attributedSubtitle
    self.isSelected = isSelected
    self.isEnabled = isEnabled
  }
}

/// A logical section inside a panel (e.g. a group on the right side of a two-column panel).
///
/// - `title`: optional section header text.
/// - `selectionMode`: desired selection semantics for `items`.
/// - `items`: options to render; concrete UI (table/chips/grid) is decided by the panel controller.
public struct FKFilterSection: Hashable, Sendable {
  public let id: FKFilterID
  public var title: String?
  public var selectionMode: FKFilterSelectionMode
  public var items: [FKFilterOptionItem]

  public init(
    id: FKFilterID,
    title: String? = nil,
    selectionMode: FKFilterSelectionMode,
    items: [FKFilterOptionItem]
  ) {
    self.id = id
    self.title = title
    self.selectionMode = selectionMode
    self.items = items
  }
}

/// Data model for a two-column panel.
///
/// Typical UI:
/// - Left: categories (`Category`)
/// - Right: sections for the currently selected category (`sectionsByCategoryID`)
///
/// This model can drive both implementations:
/// - left list + right list (`FKFilterTwoColumnListViewController`)
/// - left list + right grid (`FKFilterTwoColumnGridViewController`)
public struct FKFilterTwoColumnModel: Hashable, Sendable {
  public struct Category: Hashable, Sendable {
    public let id: FKFilterID
    public var title: String
    public var isSelected: Bool

    public init(id: FKFilterID, title: String, isSelected: Bool = false) {
      self.id = id
      self.title = title
      self.isSelected = isSelected
    }
  }

  public var categories: [Category]
  /// Mapping categoryId -> sections displayed on the right.
  public var sectionsByCategoryID: [FKFilterID: [FKFilterSection]]

  public init(categories: [Category], sectionsByCategoryID: [FKFilterID: [FKFilterSection]]) {
    self.categories = categories
    self.sectionsByCategoryID = sectionsByCategoryID
  }
}

