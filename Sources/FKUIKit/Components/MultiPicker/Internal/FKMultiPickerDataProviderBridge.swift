//
// FKMultiPickerDataProviderBridge.swift
//

import Foundation
import UIKit

@MainActor
final class FKMultiPickerDataProviderBridge: FKMultiPickerDataSource {
  private let provider: FKMultiPickerDataProviding

  init(provider: FKMultiPickerDataProviding) {
    self.provider = provider
  }

  func rootNodes(for picker: FKMultiPicker) -> [FKMultiPickerNode] {
    provider.rootNodes()
  }

  func multiPicker(
    _ picker: FKMultiPicker,
    childrenOf node: FKMultiPickerNode,
    atLevel level: Int
  ) -> [FKMultiPickerNode] {
    provider.children(of: node, atLevel: level)
  }
}
