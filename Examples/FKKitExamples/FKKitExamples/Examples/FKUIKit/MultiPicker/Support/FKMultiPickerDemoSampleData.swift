//
// FKMultiPickerDemoSampleData.swift
//

import UIKit
import FKUIKit

/// Static trees and global-style bootstrap for MultiPicker examples.
enum FKMultiPickerDemoSampleData {
  private static var didConfigureGlobalStyle = false

  static func configureGlobalStyleIfNeeded() {
    guard !didConfigureGlobalStyle else { return }
    didConfigureGlobalStyle = true
    var config = FKMultiPickerConfiguration()
    config.numberOfColumns = 4
    config.presentationStyle = .halfScreen
    config.toolbarStyle.title = "Global Picker"
    config.toolbarStyle.confirmTitleColor = .systemBlue
    config.toolbarStyle.cancelTitleColor = .secondaryLabel
    config.rowStyle.textColor = .label
    config.rowStyle.selectedTextColor = .systemBlue
    config.rowStyle.rowHeight = 40
    config.containerStyle.cornerRadius = 18
    config.containerStyle.maskColor = UIColor.black.withAlphaComponent(0.38)
    FKMultiPicker.defaultConfiguration = config
  }

  static let threeLevelCatalog: [FKMultiPickerNode] = [
    FKMultiPickerNode(
      id: "electronics",
      title: "Electronics",
      children: [
        FKMultiPickerNode(
          id: "phone",
          title: "Phone",
          children: [
            FKMultiPickerNode(id: "ios", title: "iOS"),
            FKMultiPickerNode(id: "android", title: "Android"),
            FKMultiPickerNode(id: "harmony", title: "HarmonyOS"),
          ]
        ),
        FKMultiPickerNode(
          id: "laptop",
          title: "Laptop",
          children: [
            FKMultiPickerNode(id: "ultrabook", title: "Ultrabook"),
            FKMultiPickerNode(id: "gaming", title: "Gaming"),
            FKMultiPickerNode(id: "workstation", title: "Workstation"),
          ]
        ),
        FKMultiPickerNode(
          id: "wearable",
          title: "Wearable",
          children: [
            FKMultiPickerNode(id: "watch", title: "Smart Watch"),
            FKMultiPickerNode(id: "earbuds", title: "Earbuds"),
          ]
        ),
      ]
    ),
    FKMultiPickerNode(
      id: "fashion",
      title: "Fashion",
      children: [
        FKMultiPickerNode(
          id: "men",
          title: "Men",
          children: [
            FKMultiPickerNode(id: "tops", title: "Tops"),
            FKMultiPickerNode(id: "pants", title: "Pants"),
            FKMultiPickerNode(id: "outerwear", title: "Outerwear"),
          ]
        ),
        FKMultiPickerNode(
          id: "women",
          title: "Women",
          children: [
            FKMultiPickerNode(id: "dress", title: "Dress"),
            FKMultiPickerNode(id: "shoes", title: "Shoes"),
            FKMultiPickerNode(id: "bags", title: "Bags"),
          ]
        ),
      ]
    ),
    FKMultiPickerNode(
      id: "home",
      title: "Home & Living",
      children: [
        FKMultiPickerNode(
          id: "furniture",
          title: "Furniture",
          children: [
            FKMultiPickerNode(id: "sofa", title: "Sofa"),
            FKMultiPickerNode(id: "desk", title: "Desk"),
            FKMultiPickerNode(id: "bed", title: "Bed"),
          ]
        ),
        FKMultiPickerNode(
          id: "kitchen",
          title: "Kitchen",
          children: [
            FKMultiPickerNode(id: "cookware", title: "Cookware"),
            FKMultiPickerNode(id: "appliances", title: "Small Appliances"),
          ]
        ),
      ]
    ),
  ]

  static let singleLevelPayments: [FKMultiPickerNode] = [
    FKMultiPickerNode(id: "cash", title: "Cash"),
    FKMultiPickerNode(id: "card", title: "Credit Card"),
    FKMultiPickerNode(id: "bank", title: "Bank Transfer"),
    FKMultiPickerNode(id: "wallet", title: "E-Wallet"),
    FKMultiPickerNode(id: "applepay", title: "Apple Pay"),
    FKMultiPickerNode(id: "crypto", title: "Crypto"),
    FKMultiPickerNode(id: "cod", title: "Cash on Delivery"),
  ]
}
