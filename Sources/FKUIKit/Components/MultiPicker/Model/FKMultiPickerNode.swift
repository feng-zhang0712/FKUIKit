//
// FKMultiPickerNode.swift
//
// Tree node model for FKMultiPicker.
//

import Foundation

/// Represents one item in a cascading picker tree.
public struct FKMultiPickerNode: Hashable {
  /// Stable identifier for diffing and restoring defaults.
  ///
  /// In most business scenarios this should map to backend IDs.
  public let id: String
  /// Display title in picker row.
  public let title: String
  /// Child items for the next level.
  ///
  /// An empty array means this node is currently a leaf level.
  public var children: [FKMultiPickerNode]

  /// Creates a tree node.
  ///
  /// - Parameters:
  ///   - id: Stable identifier.
  ///   - title: Display title.
  ///   - children: Child nodes for the next level.
  public init(
    id: String = UUID().uuidString,
    title: String,
    children: [FKMultiPickerNode] = []
  ) {
    self.id = id
    self.title = title
    self.children = children
  }
}
