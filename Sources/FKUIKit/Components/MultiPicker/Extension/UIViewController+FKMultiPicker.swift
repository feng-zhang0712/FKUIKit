//
// UIViewController+FKMultiPicker.swift
//
// Convenience APIs for presenting FKMultiPicker.
//

import UIKit

public extension UIViewController {
  /// Presents a multi-level picker with custom nodes.
  ///
  /// - Parameters:
  ///   - nodes: Root nodes used as picker data source.
  ///   - configuration: Picker configuration for style and behavior.
  ///   - onConfirmed: Callback executed when user confirms selection.
  /// - Returns: Presented picker instance.
  @discardableResult
  func fk_presentMultiPicker(
    nodes: [FKMultiPickerNode],
    configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    FKMultiPicker.present(in: view, nodes: nodes, configuration: configuration, onConfirmed: onConfirmed)
  }

  /// Presents a multi-level picker with custom provider.
  ///
  /// - Parameters:
  ///   - provider: Provider that resolves root and child nodes dynamically.
  ///   - configuration: Picker configuration for style and behavior.
  ///   - onConfirmed: Callback executed when user confirms selection.
  /// - Returns: Presented picker instance.
  @discardableResult
  func fk_presentMultiPicker(
    provider: FKMultiPickerDataProviding,
    configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    FKMultiPicker.present(in: view, provider: provider, configuration: configuration, onConfirmed: onConfirmed)
  }

  /// Presents built-in province/city/district/street picker.
  ///
  /// - Parameters:
  ///   - configuration: Picker configuration for style and behavior.
  ///   - onConfirmed: Callback executed when user confirms selection.
  /// - Returns: Presented picker instance.
  @discardableResult
  func fk_presentRegionPicker(
    configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    FKMultiPicker.presentRegionPicker(in: view, configuration: configuration, onConfirmed: onConfirmed)
  }
}
