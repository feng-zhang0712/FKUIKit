import Foundation

/// Stable id wrapper to avoid leaking server ids into UI directly.
public struct FKFilterID: Hashable, Sendable, RawRepresentable {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
}

public enum FKFilterSelectionMode: Sendable {
  case single
  case multiple
}

public struct FKFilterOptionItem: Hashable, Sendable {
  public let id: FKFilterID
  public var title: String
  public var isSelected: Bool
  public var isEnabled: Bool

  public init(
    id: FKFilterID,
    title: String,
    isSelected: Bool = false,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.title = title
    self.isSelected = isSelected
    self.isEnabled = isEnabled
  }
}

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

/// Two-column data: left categories + right sections for the selected category.
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

