//
//  AppRootViewController.swift
//  FKKitExamples
//

import UIKit

/// App root navigation controller for demo pages under `Examples/`.
final class AppRootViewController: UINavigationController {

  init() {
    super.init(rootViewController: ExampleMenuViewController())
    navigationBar.prefersLargeTitles = false
    applySystemNavigationBarAppearance()
  }

  /// Uses an opaque navigation bar background, similar to the Settings app.
  private func applySystemNavigationBarAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = .systemBackground
    appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

    navigationBar.standardAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
    navigationBar.compactAppearance = appearance
    navigationBar.compactScrollEdgeAppearance = appearance
    navigationBar.isTranslucent = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
