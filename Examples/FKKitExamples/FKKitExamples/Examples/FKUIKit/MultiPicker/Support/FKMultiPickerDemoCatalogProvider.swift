//
// FKMultiPickerDemoCatalogProvider.swift
//

import Foundation
import FKUIKit

/// Demo `FKMultiPickerDataProviding` with in-memory linkage (replace with network or DB in production).
@MainActor
final class FKMultiPickerDemoCatalogProvider: FKMultiPickerDataProviding {
  func rootNodes() -> [FKMultiPickerNode] {
    [
      FKMultiPickerNode(id: "food", title: "Food"),
      FKMultiPickerNode(id: "travel", title: "Travel"),
      FKMultiPickerNode(id: "sports", title: "Sports"),
      FKMultiPickerNode(id: "books", title: "Books"),
    ]
  }

  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    switch (level, node.id) {
    case (0, "food"):
      return [
        FKMultiPickerNode(id: "food-jp", title: "Japanese"),
        FKMultiPickerNode(id: "food-it", title: "Italian"),
        FKMultiPickerNode(id: "food-cn", title: "Chinese"),
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
    case (0, "books"):
      return [
        FKMultiPickerNode(id: "books-fic", title: "Fiction"),
        FKMultiPickerNode(id: "books-nonfic", title: "Non-fiction"),
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
    case (1, "food-cn"):
      return [
        FKMultiPickerNode(id: "food-cn-dimsum", title: "Dim Sum"),
        FKMultiPickerNode(id: "food-cn-noodle", title: "Noodles"),
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
    case (1, "books-fic"):
      return [
        FKMultiPickerNode(id: "books-fic-scifi", title: "Sci-Fi"),
        FKMultiPickerNode(id: "books-fic-mystery", title: "Mystery"),
      ]
    case (1, "books-nonfic"):
      return [
        FKMultiPickerNode(id: "books-nonfic-history", title: "History"),
        FKMultiPickerNode(id: "books-nonfic-bio", title: "Biography"),
      ]
    default:
      return []
    }
  }
}
