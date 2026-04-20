//
// FKMultiPickerCustomDataProvider.swift
//
// Custom provider example for protocol-driven linkage data.
//

import Foundation
import FKUIKit

/// Custom business provider that demonstrates protocol-driven linkage.
@MainActor
final class FKMultiPickerCustomDataProvider: FKMultiPickerDataProviding {
  /// Root nodes for level 0.
  func rootNodes() -> [FKMultiPickerNode] {
    [
      FKMultiPickerNode(id: "food", title: "Food"),
      FKMultiPickerNode(id: "travel", title: "Travel"),
      FKMultiPickerNode(id: "sports", title: "Sports"),
    ]
  }

  /// Child nodes loaded by parent id and level.
  ///
  /// This method can be replaced with remote or database-backed lazy loading.
  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    switch (level, node.id) {
    case (0, "food"):
      return [
        FKMultiPickerNode(id: "food-jp", title: "Japanese"),
        FKMultiPickerNode(id: "food-it", title: "Italian"),
      ]
    case (0, "travel"):
      return [
        FKMultiPickerNode(id: "travel-dom", title: "Domestic"),
        FKMultiPickerNode(id: "travel-int", title: "International"),
      ]
    case (0, "sports"):
      return [
        FKMultiPickerNode(id: "sports-team", title: "Team Sports"),
        FKMultiPickerNode(id: "sports-ind", title: "Individual Sports"),
      ]
    case (1, "food-jp"):
      return [
        FKMultiPickerNode(id: "food-jp-sushi", title: "Sushi"),
        FKMultiPickerNode(id: "food-jp-ramen", title: "Ramen"),
      ]
    case (1, "food-it"):
      return [
        FKMultiPickerNode(id: "food-it-pasta", title: "Pasta"),
        FKMultiPickerNode(id: "food-it-pizza", title: "Pizza"),
      ]
    case (1, "travel-dom"):
      return [
        FKMultiPickerNode(id: "travel-dom-weekend", title: "Weekend"),
        FKMultiPickerNode(id: "travel-dom-holiday", title: "Holiday"),
      ]
    case (1, "travel-int"):
      return [
        FKMultiPickerNode(id: "travel-int-asia", title: "Asia"),
        FKMultiPickerNode(id: "travel-int-eu", title: "Europe"),
      ]
    case (1, "sports-team"):
      return [
        FKMultiPickerNode(id: "sports-team-football", title: "Football"),
        FKMultiPickerNode(id: "sports-team-basketball", title: "Basketball"),
      ]
    case (1, "sports-ind"):
      return [
        FKMultiPickerNode(id: "sports-ind-tennis", title: "Tennis"),
        FKMultiPickerNode(id: "sports-ind-swimming", title: "Swimming"),
      ]
    default:
      return []
    }
  }
}
