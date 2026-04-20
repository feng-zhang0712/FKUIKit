//
// FKMultiPickerSelection.swift
//
// Selection result models for FKMultiPicker.
//

import Foundation

/// One selected row in a specific level.
public struct FKMultiPickerSelectionItem: Hashable {
  /// Level index in picker components.
  public let level: Int
  /// Selected row index in the level.
  public let row: Int
  /// Selected node.
  public let node: FKMultiPickerNode

  /// Creates a selected item.
  public init(level: Int, row: Int, node: FKMultiPickerNode) {
    self.level = level
    self.row = row
    self.node = node
  }
}

/// Full selection result for the current picker state.
public struct FKMultiPickerSelectionResult: Hashable {
  /// Ordered selected items from level 0 to deepest level.
  ///
  /// The array only includes levels with valid rows and data.
  public let items: [FKMultiPickerSelectionItem]

  /// Convenience joined text for quick display.
  public var joinedTitle: String {
    items.map(\.node.title).joined(separator: " ")
  }

  /// Creates a selection result.
  public init(items: [FKMultiPickerSelectionItem]) {
    self.items = items
  }
}
