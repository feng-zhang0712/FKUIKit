//
// FKMultiPickerTreeDataProvider.swift
//

import Foundation

/// Wraps a static in-memory tree as `FKMultiPickerDataProviding`.
@MainActor
public final class FKMultiPickerTreeDataProvider: FKMultiPickerDataProviding {
  private let nodes: [FKMultiPickerNode]

  public init(nodes: [FKMultiPickerNode]) {
    self.nodes = nodes
  }

  public func rootNodes() -> [FKMultiPickerNode] {
    nodes
  }

  public func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    node.children
  }
}
