//
// FKMultiPickerNode.swift
//

import Foundation

/// One row in a cascading column, optionally holding deeper levels in `children`.
public struct FKMultiPickerNode: Hashable, Sendable {
  /// Stable identifier (restore selection, analytics, server keys).
  public let id: String
  /// Text shown in the wheel.
  public let title: String
  /// Next-level nodes when using an in-memory tree (ignored when a custom `FKMultiPickerDataSource` supplies children).
  public var children: [FKMultiPickerNode]

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
