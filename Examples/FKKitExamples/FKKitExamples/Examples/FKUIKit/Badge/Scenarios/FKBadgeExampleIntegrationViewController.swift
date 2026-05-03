import UIKit
import FKUIKit

/// Standalone `UITabBar` outside `UITabBarController` often reports a small intrinsic height when embedded in
/// `UIStackView`, which squishes icons, titles, and system `badgeValue`. Force system tab bar height (49pt).
private final class FKBadgeDemoTabBar: UITabBar {

  /// Matches UIKit’s default tab bar content height when using `UITabBarController`.
  static let standardSystemHeight: CGFloat = 49

  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: Self.standardSystemHeight)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    var fitted = super.sizeThatFits(size)
    fitted.height = Self.standardSystemHeight
    return fitted
  }
}

final class FKBadgeExampleIntegrationViewController: FKBadgeExampleScrollViewController {

  private let demoTabBar = FKBadgeDemoTabBar()

  override func viewDidLoad() {
    super.viewDidLoad()
    installScrollRootChrome()
    buildTabBarSection()
    buildBarButtonItemSection()
    buildRTLSection()
  }

  private func buildTabBarSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "UITabBarItem: badgeValue + overflow")

    demoTabBar.items = [
      UITabBarItem(title: "Messages", image: UIImage(systemName: "bubble.left.fill"), tag: 0),
      UITabBarItem(title: "Profile", image: UIImage(systemName: "person.fill"), tag: 1),
    ]
    demoTabBar.selectedItem = demoTabBar.items?.first
    demoTabBar.items?.first?.fk_setBadgeCount(128, maxDisplay: 99)
    demoTabBar.translatesAutoresizingMaskIntoConstraints = false

    let tabBarHost = UIView()
    tabBarHost.translatesAutoresizingMaskIntoConstraints = false
    tabBarHost.backgroundColor = .secondarySystemBackground
    tabBarHost.layer.cornerRadius = 12
    tabBarHost.clipsToBounds = true
    tabBarHost.addSubview(demoTabBar)

    let hostHeight = tabBarHost.heightAnchor.constraint(equalToConstant: FKBadgeDemoTabBar.standardSystemHeight)
    hostHeight.priority = .required

    NSLayoutConstraint.activate([
      hostHeight,
      demoTabBar.topAnchor.constraint(equalTo: tabBarHost.topAnchor),
      demoTabBar.leadingAnchor.constraint(equalTo: tabBarHost.leadingAnchor),
      demoTabBar.trailingAnchor.constraint(equalTo: tabBarHost.trailingAnchor),
      demoTabBar.bottomAnchor.constraint(equalTo: tabBarHost.bottomAnchor),
    ])

    demoTabBar.setContentCompressionResistancePriority(.required, for: .vertical)
    demoTabBar.setContentHuggingPriority(.required, for: .vertical)
    tabBarHost.setContentCompressionResistancePriority(.required, for: .vertical)
    tabBarHost.setContentHuggingPriority(.required, for: .vertical)

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "fk_setBadgeCount(128) → 99+ (`badgeValue` uses the same overflow rules as FKBadgeFormatter). Bar height is fixed to 49pt like UIKit’s tab bar."

    box.addArrangedSubview(tabBarHost)
    box.addArrangedSubview(note)
    contentStack.addArrangedSubview(box)
  }

  private func buildBarButtonItemSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "UIBarButtonItem pattern (customView host)")

    let barStrip = UIView()
    barStrip.backgroundColor = .secondarySystemBackground
    barStrip.layer.cornerRadius = 10
    barStrip.translatesAutoresizingMaskIntoConstraints = false

    let bell = UIButton(type: .system)
    bell.setImage(UIImage(systemName: "bell.fill"), for: .normal)
    bell.tintColor = .label
    bell.translatesAutoresizingMaskIntoConstraints = false
    bell.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: 2, vertical: -2))
    bell.fk_badge.showCount(5)

    barStrip.addSubview(bell)

    NSLayoutConstraint.activate([
      barStrip.heightAnchor.constraint(equalToConstant: 52),
      bell.trailingAnchor.constraint(equalTo: barStrip.trailingAnchor, constant: -16),
      bell.centerYAnchor.constraint(equalTo: barStrip.centerYAnchor),
      bell.widthAnchor.constraint(equalToConstant: 40),
      bell.heightAnchor.constraint(equalToConstant: 40),
    ])

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "Same layout as UIBarButtonItem(customView:)."

    box.addArrangedSubview(barStrip)
    box.addArrangedSubview(note)
    contentStack.addArrangedSubview(box)
  }

  private func buildRTLSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "RTL: forceRightToLeft")

    let wrap = UIView()
    wrap.semanticContentAttribute = .forceRightToLeft
    wrap.backgroundColor = .secondarySystemFill
    wrap.layer.cornerRadius = 12
    wrap.translatesAutoresizingMaskIntoConstraints = false

    let chip = FKBadgeExampleSupport.makeChipTarget()
    chip.fk_badge.showCount(9)
    chip.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -4, vertical: 4))
    wrap.addSubview(chip)

    NSLayoutConstraint.activate([
      wrap.heightAnchor.constraint(equalToConstant: 80),
      chip.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -20),
      chip.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
    ])

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "Trailing anchor mirrors with layout direction."

    box.addArrangedSubview(wrap)
    box.addArrangedSubview(note)
    contentStack.addArrangedSubview(box)
  }
}
