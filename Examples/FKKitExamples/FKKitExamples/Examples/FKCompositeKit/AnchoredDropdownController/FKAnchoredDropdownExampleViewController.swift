import UIKit
import FKCompositeKit
import FKUIKit

/// Examples for `FKAnchoredDropdownController`.
final class FKAnchoredDropdownExampleViewController: UIViewController {
  private enum TabID: String, CaseIterable, Hashable {
    case sort
    case filters
    case search

    var title: String {
      switch self {
      case .sort: return "Sort"
      case .filters: return "Filters"
      case .search: return "Search"
      }
    }
  }

  private final class TabBarHostView: UIView, FKAnchoredDropdownTabBarHost {
    let tabBar: FKTabBar = {
      let bar = FKTabBar()
      bar.translatesAutoresizingMaskIntoConstraints = false
      return bar
    }()

    private let container = UIView()
    private let divider = UIView()

    override init(frame: CGRect) {
      super.init(frame: frame)
      commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    var view: UIView { self }

    private func commonInit() {
      // Keep host transparent so underlying demo content (log text view) stays visible.
      // Only the top tab bar container should be opaque.
      backgroundColor = .clear
      container.backgroundColor = .systemBackground

      container.translatesAutoresizingMaskIntoConstraints = false
      divider.translatesAutoresizingMaskIntoConstraints = false
      divider.backgroundColor = UIColor.separator.withAlphaComponent(0.65)

      addSubview(container)
      container.addSubview(tabBar)
      container.addSubview(divider)

      NSLayoutConstraint.activate([
        container.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
        container.leadingAnchor.constraint(equalTo: leadingAnchor),
        container.trailingAnchor.constraint(equalTo: trailingAnchor),

        tabBar.topAnchor.constraint(equalTo: container.topAnchor),
        tabBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        tabBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        tabBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

        divider.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
        divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        divider.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
    }
  }

  private let logView = UITextView()
  private let host = TabBarHostView()
  private lazy var dropdown: FKAnchoredDropdownController<TabID> = makeDropdown()
  private let animationControl = UISegmentedControl(items: ["Replace", "Dismiss→Present"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tab Dropdown"
    view.backgroundColor = .systemBackground
    setupNavigation()
    setupChild()
    setupLogView()
    appendLog("Ready. Tap tabs to open/close/switch.")
  }

  private func setupNavigation() {
    animationControl.selectedSegmentIndex = 0
    animationControl.addTarget(self, action: #selector(didChangeAnimationStyle), for: .valueChanged)
    navigationItem.titleView = animationControl

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(didTapOpenFilters)),
      UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(didTapClose)),
    ]
  }

  private func setupChild() {
    addChild(dropdown)
    dropdown.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(dropdown.view)
    dropdown.didMove(toParent: self)

    NSLayoutConstraint.activate([
      dropdown.view.topAnchor.constraint(equalTo: view.topAnchor),
      dropdown.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dropdown.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dropdown.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupLogView() {
    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.backgroundColor = UIColor.secondarySystemBackground
    logView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logView.layer.cornerRadius = 10
    logView.layer.masksToBounds = true

    // Layering contract:
    // base view < logView < dropdown presentation < tab bar
    view.insertSubview(logView, belowSubview: dropdown.view)
    NSLayoutConstraint.activate([
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      logView.heightAnchor.constraint(equalToConstant: 180),
    ])
    view.bringSubviewToFront(dropdown.view)
  }

  private func makeDropdown() -> FKAnchoredDropdownController<TabID> {
    let tabs: [FKAnchoredDropdownTab<TabID>] = [
      .chevronTitle(
        id: .sort,
        itemID: "sort",
        title: { "Sort" },
        content: .viewController { SortPanelViewController() }
      ),
      .chevronTitle(
        id: .filters,
        itemID: "filters",
        title: { "Filters" },
        subtitle: { "3 selected" },
        content: .viewController { FiltersPanelViewController() }
      ),
      .chevronTitle(
        id: .search,
        itemID: "search",
        title: { "Search" },
        content: .viewController { SearchPanelViewController() }
      ),
    ]

    var config = FKAnchoredDropdownConfiguration.default
    config.presentationConfiguration.contentInsets = .init(top: 8, leading: 12, bottom: 12, trailing: 12)
    config.presentationConfiguration.cornerRadius = 12
    config.presentationConfiguration.backdropStyle = .dim(alpha: 0.25)
    config.switchAnimationStyle = .replaceInPlace(animation: .crossfade(duration: 0.18))

    let callbacks = FKAnchoredDropdownConfiguration.Callbacks<TabID>(
      stateDidChange: { [weak self] state in self?.appendLog("state: \(state)") },
      expandedTabDidChange: { [weak self] expanded in self?.appendLog("expandedTab: \(expanded?.rawValue ?? "nil")") },
      willOpen: { [weak self] tab in self?.appendLog("willOpen: \(tab.rawValue)") },
      didOpen: { [weak self] tab in self?.appendLog("didOpen: \(tab.rawValue)") },
      willClose: { [weak self] tab, reason in self?.appendLog("willClose: \(tab?.rawValue ?? "nil") reason=\(reason)") },
      didClose: { [weak self] tab, reason in self?.appendLog("didClose: \(tab?.rawValue ?? "nil") reason=\(reason)") },
      willSwitch: { [weak self] from, to in self?.appendLog("willSwitch: \(from.rawValue) → \(to.rawValue)") },
      didSwitch: { [weak self] from, to in self?.appendLog("didSwitch: \(from.rawValue) → \(to.rawValue)") }
    )

    let vc = FKAnchoredDropdownController<TabID>(
      tabs: tabs,
      tabBarHost: host,
      configuration: config,
      callbacks: callbacks
    )

    // Demonstrate external "state restore" style API: preselect but do not open.
    vc.select(tab: .filters, animated: false)
    return vc
  }

  private func appendLog(_ text: String) {
    let line = "[\(Self.timeString())] \(text)"
    if logView.text?.isEmpty ?? true {
      logView.text = line
    } else {
      logView.text = (logView.text ?? "") + "\n" + line
    }
    let range = NSRange(location: max(0, logView.text.count - 1), length: 1)
    logView.scrollRangeToVisible(range)
  }

  private static func timeString() -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f.string(from: Date())
  }

  @objc private func didTapOpenFilters() {
    dropdown.open(tab: .filters, animated: true)
  }

  @objc private func didTapClose() {
    dropdown.close(animated: true)
  }

  @objc private func didChangeAnimationStyle() {
    switch animationControl.selectedSegmentIndex {
    case 0:
      dropdown.configuration.switchAnimationStyle = .replaceInPlace(animation: .crossfade(duration: 0.18))
      appendLog("switchAnimationStyle = replaceInPlace(crossfade)")
    default:
      dropdown.configuration.switchAnimationStyle = .dismissThenPresent(dismissAnimated: false, presentAnimated: true)
      appendLog("switchAnimationStyle = dismissThenPresent")
    }
  }

}

private final class SortPanelViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    preferredContentSize = CGSize(width: 0, height: 320)

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.text = "Sort"
    title.font = .preferredFont(forTextStyle: .headline)

    let hint = UILabel()
    hint.text = "Tap any option to see immediate height stability."
    hint.textColor = .secondaryLabel
    hint.font = .preferredFont(forTextStyle: .subheadline)
    hint.numberOfLines = 0

    let options = ["Recommended", "Distance", "Price ↑", "Price ↓", "Rating"]
    let buttons = options.map { text -> UIButton in
      var config = UIButton.Configuration.filled()
      config.title = text
      config.baseBackgroundColor = .secondarySystemBackground
      config.baseForegroundColor = .label
      let b = UIButton(configuration: config)
      b.contentHorizontalAlignment = .leading
      b.addTarget(self, action: #selector(didTapOption), for: .touchUpInside)
      return b
    }

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(hint)
    buttons.forEach { stack.addArrangedSubview($0) }

    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  @objc private func didTapOption() {
    // no-op: used to demonstrate tap handling inside content
  }
}

private final class FiltersPanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var rows: [String] = (1...18).map { "Filter option \($0)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Encourage intrinsic height measurement while still allowing internal scrolling:
    // FKPresentationController will clamp by available space and content will scroll.
    preferredContentSize = CGSize(width: 0, height: 420)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.textLabel?.text = rows[indexPath.row]
    cell.detailTextLabel?.text = "Tap to simulate content height change"
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    // Simulate a dynamic height change (e.g. async load expanding a section).
    if rows.count < 26 {
      rows.append(contentsOf: (rows.count + 1...rows.count + 6).map { "Filter option \($0)" })
      tableView.reloadData()
      preferredContentSize.height += 120
    } else {
      rows = (1...18).map { "Filter option \($0)" }
      tableView.reloadData()
      preferredContentSize.height = 420
    }
  }
}

private final class SearchPanelViewController: UIViewController, UITextFieldDelegate {
  private let field = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    preferredContentSize = CGSize(width: 0, height: 180)

    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = "Search"
    title.font = .preferredFont(forTextStyle: .headline)

    field.translatesAutoresizingMaskIntoConstraints = false
    field.borderStyle = .roundedRect
    field.placeholder = "Type to test keyboard avoidance"
    field.returnKeyType = .done
    field.delegate = self

    let hint = UILabel()
    hint.translatesAutoresizingMaskIntoConstraints = false
    hint.text = "Keyboard avoidance comes from FKPresentationController configuration."
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0
    hint.font = .preferredFont(forTextStyle: .subheadline)

    view.addSubview(title)
    view.addSubview(field)
    view.addSubview(hint)
    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
      title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

      field.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
      field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

      hint.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 12),
      hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      hint.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
    ])
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

