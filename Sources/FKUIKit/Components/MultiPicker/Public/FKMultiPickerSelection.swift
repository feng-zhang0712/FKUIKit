//
// FKMultiPickerSelection.swift
//

import Foundation

/// One selected wheel position at a given depth.
public struct FKMultiPickerSelectionItem: Hashable {
  /// Column index (0 = leftmost / root column).
  public let level: Int
  /// Row index in that column.
  public let row: Int
  public let node: FKMultiPickerNode

  public init(level: Int, row: Int, node: FKMultiPickerNode) {
    self.level = level
    self.row = row
    self.node = node
  }
}

/// Snapshot of the current or confirmed path through the tree.
public struct FKMultiPickerSelectionResult: Hashable {
  public let items: [FKMultiPickerSelectionItem]

  /// Titles from root to leaf, space-separated.
  public var joinedTitle: String {
    items.map(\.node.title).joined(separator: " ")
  }

  public init(items: [FKMultiPickerSelectionItem]) {
    self.items = items
  }
}

public extension FKMultiPickerSelectionResult {
  /// Node ids ordered by `level`, suitable for `FKMultiPickerConfiguration.defaultSelectionKeys`.
  var selectionKeys: [String] {
    items.sorted { $0.level < $1.level }.map(\.node.id)
  }
}
