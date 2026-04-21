//
// FKCarouselDemoSupport.swift
//
// Shared helpers for FKCarousel demo pages.
//

import FKUIKit
import UIKit

enum FKCarouselDemoSupport {
  /// Applies a global style template once for all carousel demos.
  @MainActor
  static func configureGlobalStyleIfNeeded() {
    guard !didConfigureGlobalStyle else { return }
    didConfigureGlobalStyle = true

    var global = FKCarouselConfiguration()
    global.autoScrollInterval = 3
    global.containerStyle.cornerRadius = 12
    global.containerStyle.contentMode = .scaleAspectFill
    global.pageControlStyle.selectedColor = .white
    global.pageControlStyle.normalColor = UIColor.white.withAlphaComponent(0.45)
    FKCarouselManager.shared.templateConfiguration = global
  }

  /// Generates demo local images to avoid asset dependency.
  static func localImageItems() -> [FKCarouselItem] {
    let colors: [UIColor] = [.systemBlue, .systemTeal, .systemOrange, .systemPurple]
    return colors.enumerated().map { index, color in
      .image(makeDemoImage(size: CGSize(width: 1200, height: 540), color: color, title: "Local Banner \(index + 1)"))
    }
  }

  /// Builds remote image demo URLs.
  static func remoteImageItems() -> [FKCarouselItem] {
    let urls: [String] = [
      "https://picsum.photos/id/1015/1200/540",
      "https://picsum.photos/id/1016/1200/540",
      "https://picsum.photos/id/1025/1200/540",
      "https://invalid.fkkit.example/404.jpg", // Intentionally invalid for error image demo.
    ]
    return urls.compactMap { URL(string: $0) }.map(FKCarouselItem.url)
  }

  /// Creates reusable placeholder image.
  static func placeholderImage() -> UIImage {
    makeDemoImage(size: CGSize(width: 80, height: 80), color: .systemGray4, title: "Loading")
  }

  /// Creates reusable failure image.
  static func failureImage() -> UIImage {
    makeDemoImage(size: CGSize(width: 80, height: 80), color: .systemRed, title: "Failed")
  }

  /// Creates a tiny single-item image.
  static func singleImageItem() -> [FKCarouselItem] {
    [.image(makeDemoImage(size: CGSize(width: 1200, height: 540), color: .systemIndigo, title: "Single Item"))]
  }

  static func customCardItems() -> [FKCarouselItem] {
    (1...4).map { index in
      .customViewProvider {
        let card = UIView()
        card.backgroundColor = [.systemPink, .systemGreen, .systemBlue, .systemOrange][index - 1]

        let title = UILabel()
        title.text = "Custom Card \(index)"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "Reusable custom UIView content"
        subtitle.font = .systemFont(ofSize: 14, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(title)
        card.addSubview(subtitle)

        NSLayoutConstraint.activate([
          title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
          title.bottomAnchor.constraint(equalTo: card.centerYAnchor, constant: -2),
          subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
          subtitle.topAnchor.constraint(equalTo: card.centerYAnchor, constant: 2),
        ])
        return card
      }
    }
  }

  /// Mutates and returns a config instance in one expression to mimic chain-style setup.
  static func makeConfig(_ mutation: (inout FKCarouselConfiguration) -> Void) -> FKCarouselConfiguration {
    var config = FKCarouselConfiguration()
    mutation(&config)
    return config
  }

  private static var didConfigureGlobalStyle = false
}

private extension FKCarouselDemoSupport {
  static func makeDemoImage(size: CGSize, color: UIColor, title: String) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))

      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .center
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 54, weight: .bold),
        .foregroundColor: UIColor.white,
        .paragraphStyle: paragraph,
      ]
      let textRect = CGRect(x: 24, y: (size.height - 70) * 0.5, width: size.width - 48, height: 70)
      title.draw(in: textRect, withAttributes: attrs)
    }
  }
}
