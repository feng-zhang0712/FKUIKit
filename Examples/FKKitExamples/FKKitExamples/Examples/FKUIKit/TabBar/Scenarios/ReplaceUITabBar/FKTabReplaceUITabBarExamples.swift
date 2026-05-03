import UIKit
import FKUIKit

/// Demonstrates using `FKTabBar` as a bottom-docked bar similar to `UITabBar`.
///
/// Key points:
/// - This is a UIView-level replacement demo only (no TabBarController is provided).
/// - Safe-area inclusion in height is controlled by layout configuration (see `safeAreaHeightPolicy`).
/// - Background, divider position, and shadow are configured via `FKTabBarAppearance`.
final class FKTabBarReplaceUITabBarExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration()
  private var items = FKTabBarExampleSupport.makeItems(5)

  private lazy var tabView: FKTabBar = {
    FKTabBar(items: items, selectedIndex: 0, configuration: configuration)
  }()

  private var bottomConstraint: NSLayoutConstraint?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Replace UITabBar"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view, topInset: 16)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Bottom-docked FKTabBar (UIView only)"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("This page demonstrates pinning FKTabBar to the bottom and toggling safe-area height policy and background styling. FKTabBar does not provide a TabBarController."))

    let safeArea = UISegmentedControl(items: ["Exclude Safe Area", "Include Safe Area"])
    safeArea.selectedSegmentIndex = 0
    safeArea.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.safeAreaHeightPolicy = safeArea.selectedSegmentIndex == 0 ? .excludeBottomSafeArea : .includeBottomSafeArea
      self.tabView.configuration = self.configuration
      self.tabView.invalidateIntrinsicContentSize()
      self.view.setNeedsLayout()
    }, for: .valueChanged)
    stack.addArrangedSubview(safeArea)

    let itemDirection = UISegmentedControl(items: ["Horizontal", "Vertical"])
    itemDirection.selectedSegmentIndex = 0
    itemDirection.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.itemLayoutDirection = itemDirection.selectedSegmentIndex == 0 ? .horizontal : .vertical
      self.tabView.configuration = self.configuration
      self.tabView.realignSelection(animated: false)
    }, for: .valueChanged)
    stack.addArrangedSubview(itemDirection)

    let surface = UISegmentedControl(items: ["Solid", "Blur"])
    surface.selectedSegmentIndex = 0
    surface.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      if surface.selectedSegmentIndex == 0 {
        self.configuration.appearance.backgroundStyle = .solid(.secondarySystemBackground)
      } else {
        self.configuration.appearance.backgroundStyle = .systemBlur(.systemMaterial)
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(surface)

    let divider = UISegmentedControl(items: ["Divider Top", "Divider Bottom", "No Divider"])
    divider.selectedSegmentIndex = 0
    divider.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      switch divider.selectedSegmentIndex {
      case 1:
        self.configuration.appearance.showsDivider = true
        self.configuration.appearance.dividerPosition = .bottom
      case 2:
        self.configuration.appearance.showsDivider = false
      default:
        self.configuration.appearance.showsDivider = true
        self.configuration.appearance.dividerPosition = .top
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(divider)

    let shadow = UISegmentedControl(items: ["Shadow On", "Shadow Off"])
    shadow.selectedSegmentIndex = 0
    shadow.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      if shadow.selectedSegmentIndex == 0 {
        self.configuration.appearance.shadow = .init(color: .black, opacity: 0.12, radius: 10, offset: .init(width: 0, height: -2))
      } else {
        self.configuration.appearance.shadow = .init(color: .black, opacity: 0, radius: 0, offset: .zero)
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(shadow)

    let hint = UILabel()
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0
    hint.text = "Tip: run on a device/simulator with Home Indicator to see the safe-area height difference."
    stack.addArrangedSubview(hint)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)

    // Default configuration to mimic a system bar-ish look in fixedEqual mode.
    configuration.layout.isScrollable = false
    configuration.layout.widthMode = .fillEqually
    configuration.layout.preferredBarHeight = 49
    configuration.layout.safeAreaHeightPolicy = .excludeBottomSafeArea
    configuration.appearance.backgroundStyle = .solid(.secondarySystemBackground)
    configuration.appearance.showsDivider = true
    configuration.appearance.dividerPosition = .top
    configuration.appearance.shadow = .init(color: .black, opacity: 0.12, radius: 10, offset: .init(width: 0, height: -2))
    tabView.configuration = configuration

    bottomConstraint = tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    bottomConstraint?.isActive = true

    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }
}

