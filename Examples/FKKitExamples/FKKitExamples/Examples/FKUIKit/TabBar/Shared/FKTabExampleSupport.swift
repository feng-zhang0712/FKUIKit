import UIKit
import FKUIKit

enum FKTabBarExampleSupport {
  static func makeItems(_ count: Int, localizedTitles: [String]? = nil) -> [FKTabBarItem] {
    let baseTitles = localizedTitles ?? [
      NSLocalizedString("Home", comment: ""),
      NSLocalizedString("Explore", comment: ""),
      NSLocalizedString("Inbox", comment: ""),
      NSLocalizedString("Profile", comment: ""),
      NSLocalizedString("Settings", comment: ""),
      NSLocalizedString("Video", comment: ""),
      NSLocalizedString("Shop", comment: ""),
      NSLocalizedString("Updates", comment: ""),
      NSLocalizedString("Favorites", comment: ""),
      NSLocalizedString("Archive", comment: ""),
      NSLocalizedString("More", comment: ""),
    ]
    let baseIcons = [
      "house", "safari", "tray", "person.crop.circle", "gearshape",
      "play.rectangle", "bag", "bell", "heart", "archivebox", "ellipsis.circle",
    ]
    let n = max(1, min(count, min(baseTitles.count, baseIcons.count)))
    return (0..<n).map { idx in
      FKTabBarItem(
        id: "tab-\(idx)",
        title: .init(normal: .init(text: baseTitles[idx])),
        image: .init(normal: .init(source: .systemSymbol(name: baseIcons[idx]))),
        accessibilityLabel: baseTitles[idx]
      )
    }
  }

  static func makeLongTitleItems() -> [FKTabBarItem] {
    let titles = [
      "Overview",
      "Very Long Financial Dashboard",
      "Notifications Center and Activity Feed",
      "Account Preferences and Privacy",
      "Experimental Feature Flags",
      "Insights",
      "Security",
      "Support",
      "History",
      "Downloads",
      "About This Application",
    ]
    return makeItems(titles.count, localizedTitles: titles)
  }

  static func makeMixedContentItems() -> [FKTabBarItem] {
    [
      FKTabBarItem(id: "text", title: .init(normal: .init(text: "Text"))),
      FKTabBarItem(
        id: "symbol",
        title: .init(normal: .init(text: "Symbol")),
        image: .init(normal: .init(source: .systemSymbol(name: "paperplane.fill"))),
        accessibilityLabel: "System symbol"
      ),
      FKTabBarItem(
        id: "image",
        title: .init(normal: .init(text: "Image")),
        image: .init(
          normal: .init(source: .asset(name: "tab_profile_placeholder")),
          selected: .init(source: .systemSymbol(name: "photo"))
        )
      ),
      FKTabBarItem(
        id: "custom",
        title: .init(normal: .init(text: "Custom")),
        customContentIdentifier: "pill",
        accessibilityLabel: "Custom content"
      ),
    ]
  }

  static func makeRootStack(in view: UIView, topInset: CGFloat = 66) -> UIStackView {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(stack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
      stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])

    return stack
  }

  static func titleLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func captionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func actionButton(_ title: String, onTap: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    var config = UIButton.Configuration.plain()
    config.title = title
    config.baseForegroundColor = .systemBlue
    config.background.backgroundColor = .secondarySystemFill
    config.background.cornerRadius = 10
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    button.configuration = config
    button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
    return button
  }
}

