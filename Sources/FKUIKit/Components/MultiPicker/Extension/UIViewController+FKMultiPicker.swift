//
// UIViewController+FKMultiPicker.swift
//

import UIKit

public extension UIViewController {
  @discardableResult
  func fk_presentFKMultiPicker(
    roots: [FKMultiPickerNode],
    configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    FKMultiPicker.present(in: view, roots: roots, configuration: configuration, onConfirmed: onConfirmed)
  }

  @discardableResult
  func fk_presentFKMultiPicker(
    dataProvider: FKMultiPickerDataProviding,
    configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    FKMultiPicker.present(in: view, dataProvider: dataProvider, configuration: configuration, onConfirmed: onConfirmed)
  }

  @discardableResult
  func fk_presentFKMultiPickerSampleAddress(
    configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    FKMultiPicker.presentSampleAddressPicker(in: view, configuration: configuration, onConfirmed: onConfirmed)
  }
}
