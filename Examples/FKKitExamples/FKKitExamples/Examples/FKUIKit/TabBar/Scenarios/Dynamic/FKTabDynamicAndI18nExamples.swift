import UIKit
import FKUIKit

final class FKTabBarDynamicDataExampleViewController: UIViewController {
  private var sourceItems = FKTabBarExampleSupport.makeItems(8)
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(5), selectedIndex: 2)
  private let modeControl = UISegmentedControl(items: ["Preserve", "Reset", "Nearest"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic data"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Runtime tab add/remove"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Use mode switch to compare preserve/reset/nearestAvailable strategies."))

    modeControl.selectedSegmentIndex = 0
    stack.addArrangedSubview(modeControl)

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Use 3 tabs") { [weak self] in
      self?.apply(count: 3)
    })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Use 8 tabs") { [weak self] in
      self?.apply(count: 8)
    })
    stack.addArrangedSubview(actions)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Toggle hidden for item #3") { [weak self] in
      guard let self, self.sourceItems.indices.contains(2) else { return }
      self.sourceItems[2].isHidden.toggle()
      self.apply(count: self.sourceItems.count)
    })

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  private func apply(count: Int) {
    let policy: FKTabBar.ItemsUpdatePolicy
    switch modeControl.selectedSegmentIndex {
    case 1: policy = .resetSelection
    case 2: policy = .nearestAvailable
    default: policy = .preserveSelection
    }
    tabView.reload(items: Array(sourceItems.prefix(max(1, count))), updatePolicy: policy)
  }
}

final class FKTabBarI18nA11yExampleViewController: UIViewController {
  private var rtl = false
  private lazy var tabView: FKTabBar = {
    var items = FKTabBarExampleSupport.makeItems(6, localizedTitles: [
      "Home", "探索", "Mes messages", "Настройки", "Perfil", "الإعدادات"
    ])
    items[1].accessibilityLabel = "Explore Chinese"
    items[5].accessibilityLabel = "Arabic settings"
    let tab = FKTabBar(items: items, selectedIndex: 0)
    return tab
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "i18n and a11y"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Multilingual labels, RTL, Dynamic Type and VoiceOver"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Use at least one non-English language and verify selected trait announcements with VoiceOver."))

    let rtlButton = FKTabBarExampleSupport.actionButton("Toggle RTL") { [weak self] in
      guard let self else { return }
      self.rtl.toggle()
      self.view.semanticContentAttribute = self.rtl ? .forceRightToLeft : .unspecified
      self.tabView.semanticContentAttribute = self.rtl ? .forceRightToLeft : .unspecified
    }
    stack.addArrangedSubview(rtlButton)

    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("For Dynamic Type: Settings > Accessibility > Display & Text Size > Larger Text."))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("For VoiceOver: Settings > Accessibility > VoiceOver. Selected tabs should read selected state."))

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }
}

final class FKTabBarFKUIKitReuseExampleViewController: UIViewController {
  private let blurHost = FKBlurView()
  private let tabView: FKTabBar

  init() {
    var configuration = FKTabBarDefaults.defaultConfiguration
    configuration.appearance.backgroundStyle = .solid(.clear)
    configuration.appearance.colors.selectedText = .systemTeal
    configuration.appearance.colors.selectedIcon = .systemTeal
    configuration.appearance.colors.indicator = .systemTeal
    configuration.appearance.indicatorStyle = .pill(
      FKTabBarBackgroundIndicatorConfiguration(
        insets: .init(top: 6, leading: 8, bottom: 6, trailing: 8),
        cornerRadius: 999,
        fill: .solid(UIColor.systemTeal.withAlphaComponent(0.14))
      )
    )
    tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(5), selectedIndex: 0, configuration: configuration)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKUIKit reuse"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Shared visual language using FKBlurView"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab surface is rendered on top of FKUIKit blur to show cross-component style consistency. Selected pill uses a themed translucent fill instead of opaque block color."))

    blurHost.configuration = FKBlurConfiguration(
      mode: .static,
      backend: .system(style: .systemMaterial),
      opacity: 1,
      downsampleFactor: 2,
      preferredFramesPerSecond: 30
    )
    blurHost.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(blurHost, at: 0)
    NSLayoutConstraint.activate([
      blurHost.topAnchor.constraint(equalTo: view.topAnchor),
      blurHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      blurHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      blurHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }
}

