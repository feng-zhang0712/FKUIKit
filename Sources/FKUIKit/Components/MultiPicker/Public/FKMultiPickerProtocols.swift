//
// FKMultiPickerProtocols.swift
//

import Foundation
import UIKit

// MARK: - Data source (advanced)

/// Supplies roots and children with access to the live `FKMultiPicker` instance.
@MainActor
public protocol FKMultiPickerDataSource: AnyObject {
  func rootNodes(for picker: FKMultiPicker) -> [FKMultiPickerNode]
  func multiPicker(
    _ picker: FKMultiPicker,
    childrenOf node: FKMultiPickerNode,
    atLevel level: Int
  ) -> [FKMultiPickerNode]
}

public extension FKMultiPickerDataSource {
  func multiPicker(
    _ picker: FKMultiPicker,
    childrenOf node: FKMultiPickerNode,
    atLevel level: Int
  ) -> [FKMultiPickerNode] {
    node.children
  }
}

// MARK: - Provider (app-friendly)

/// Lightweight tree source without a `picker` parameter (typical app / network-backed trees).
@MainActor
public protocol FKMultiPickerDataProviding: AnyObject {
  func rootNodes() -> [FKMultiPickerNode]
  /// Child rows for the next column after selecting `node` in column `level`.
  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode]
}

public extension FKMultiPickerDataProviding {
  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    node.children
  }
}

// MARK: - Delegate

@MainActor
public protocol FKMultiPickerDelegate: AnyObject {
  func multiPickerDidCancel(_ picker: FKMultiPicker)
  func multiPicker(_ picker: FKMultiPicker, didChange result: FKMultiPickerSelectionResult)
  func multiPicker(_ picker: FKMultiPicker, didConfirm result: FKMultiPickerSelectionResult)
}

public extension FKMultiPickerDelegate {
  func multiPickerDidCancel(_ picker: FKMultiPicker) {}
  func multiPicker(_ picker: FKMultiPicker, didChange result: FKMultiPickerSelectionResult) {}
  func multiPicker(_ picker: FKMultiPicker, didConfirm result: FKMultiPickerSelectionResult) {}
}
