//
// FKMultiPickerProtocols.swift
//
// Protocol abstractions for FKMultiPicker.
//

import Foundation

/// Data source abstraction for `FKMultiPicker`.
@MainActor
public protocol FKMultiPickerDataSource: AnyObject {
  /// Returns root nodes for level 0.
  ///
  /// - Parameter picker: Picker requesting root data.
  /// - Returns: Root-level nodes.
  func rootNodes(for picker: FKMultiPicker) -> [FKMultiPickerNode]
  /// Returns child nodes for a parent node.
  ///
  /// - Parameters:
  ///   - picker: Picker requesting child data.
  ///   - node: Selected parent node.
  ///   - level: Parent level index.
  /// - Returns: Child nodes for next level.
  func multiPicker(
    _ picker: FKMultiPicker,
    childrenOf node: FKMultiPickerNode,
    atLevel level: Int
  ) -> [FKMultiPickerNode]
}

public extension FKMultiPickerDataSource {
  /// Default child resolving behavior using embedded node children.
  ///
  /// - Parameters:
  ///   - picker: Picker requesting child data.
  ///   - node: Selected parent node.
  ///   - level: Parent level index.
  /// - Returns: `node.children`.
  func multiPicker(
    _ picker: FKMultiPicker,
    childrenOf node: FKMultiPickerNode,
    atLevel level: Int
  ) -> [FKMultiPickerNode] {
    node.children
  }
}

/// Delegate abstraction for picker lifecycle and interaction callbacks.
@MainActor
public protocol FKMultiPickerDelegate: AnyObject {
  /// Called when user taps cancel or dismisses by mask.
  ///
  /// - Parameter picker: Picker that was cancelled.
  func multiPickerDidCancel(_ picker: FKMultiPicker)
  /// Called when selection changes in realtime.
  ///
  /// - Parameters:
  ///   - picker: Picker emitting the callback.
  ///   - result: Current selection snapshot.
  func multiPicker(_ picker: FKMultiPicker, didChange result: FKMultiPickerSelectionResult)
  /// Called when user confirms current selection.
  ///
  /// - Parameters:
  ///   - picker: Picker emitting the callback.
  ///   - result: Confirmed selection snapshot.
  func multiPicker(_ picker: FKMultiPicker, didConfirm result: FKMultiPickerSelectionResult)
}

public extension FKMultiPickerDelegate {
  /// Optional default empty implementation.
  func multiPickerDidCancel(_ picker: FKMultiPicker) {}
  /// Optional default empty implementation.
  func multiPicker(_ picker: FKMultiPicker, didChange result: FKMultiPickerSelectionResult) {}
  /// Optional default empty implementation.
  func multiPicker(_ picker: FKMultiPicker, didConfirm result: FKMultiPickerSelectionResult) {}
}
