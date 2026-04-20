//
// FKMultiPickerDataProvider.swift
//
// Data provider implementations for FKMultiPicker.
//

import Foundation

/// Data provider protocol for standalone tree source.
@MainActor
public protocol FKMultiPickerDataProviding: AnyObject {
  /// Returns root nodes of picker tree.
  ///
  /// - Returns: Root-level nodes.
  func rootNodes() -> [FKMultiPickerNode]
  /// Returns children for parent node and level.
  ///
  /// - Parameters:
  ///   - node: Selected parent node.
  ///   - level: Parent level index.
  /// - Returns: Child nodes for the next level.
  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode]
}

public extension FKMultiPickerDataProviding {
  /// Default child resolving behavior using embedded node children.
  ///
  /// - Parameters:
  ///   - node: Selected parent node.
  ///   - level: Parent level index.
  /// - Returns: `node.children`.
  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    node.children
  }
}

/// Default tree provider based on in-memory node graph.
@MainActor
public final class FKMultiPickerTreeDataProvider: FKMultiPickerDataProviding {
  /// Immutable root nodes used by the provider.
  private let nodes: [FKMultiPickerNode]

  /// Creates a provider from static tree nodes.
  ///
  /// - Parameter nodes: Root nodes at level 0.
  public init(nodes: [FKMultiPickerNode]) {
    self.nodes = nodes
  }

  /// Returns root nodes passed at initialization.
  ///
  /// - Returns: Root-level nodes.
  public func rootNodes() -> [FKMultiPickerNode] {
    nodes
  }

  /// Returns children from the embedded tree.
  ///
  /// - Parameters:
  ///   - node: Selected parent node.
  ///   - level: Parent level index.
  /// - Returns: Child nodes for the next level.
  public func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    node.children
  }
}
