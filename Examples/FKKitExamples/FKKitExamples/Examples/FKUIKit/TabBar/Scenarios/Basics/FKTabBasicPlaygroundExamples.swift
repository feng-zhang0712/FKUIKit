import UIKit
import FKUIKit

/// A single-page "playground" demonstrating the most essential `FKTabBar` integration points.
///
/// What this page demonstrates:
/// - Minimal setup: items, selected index, and selection callbacks.
/// - Two layout modes: `fixedEqual` (non-scrollable) and `scrollable` (intrinsic width).
/// - `enabled == false` behavior: disabled tabs are not selectable and do not emit callbacks.
/// - Programmatic selection with `notify` toggle (visual update without outward notifications).
/// - Reloading items via `reload(items:)` without creating any controller/paging wrapper.
///
/// What `FKTabBar` does NOT do:
/// - It does not own or manage any paging controller / TabBarController.
/// - It only renders UI and exposes selection/progress APIs for external coordination.
final class FKTabBarBasicPlaygroundExampleViewController: UIViewController, FKTabBarDelegate {
  private enum LayoutMode: Int {
    case fixedEqual = 0
    case scrollable = 1
  }

  private var layoutMode: LayoutMode = .fixedEqual
  private var isTab2Enabled: Bool = true
  private var shouldNotifyProgrammaticSelection: Bool = true

  private var items: [FKTabBarItem] = []
  private var configuration = FKTabBarConfiguration(layout: .init())

  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(items: items, selectedIndex: 0, configuration: configuration)
    tab.delegate = self
    tab.onReselect = { [weak self] item, index in
      self?.appendLog("onReselect: \(index) (\(item.titleText ?? item.id))")
    }
    tab.onSelectionChanged = { [weak self] item, index, reason in
      self?.appendLog("onSelectionChanged: \(index) (\(item.titleText ?? item.id)), reason: \(reason)")
    }
    return tab
  }()

  private let modeControl = UISegmentedControl(items: ["FixedEqual", "Scrollable"])
  private let notifyControl = UISegmentedControl(items: ["Notify: On", "Notify: Off"])
  private let tapEventPolicyControl = UISegmentedControl(items: ["Tap Event: Once", "Tap Event: Always"])
  private let enabledSwitch = UISwitch()
  private let logView = UITextView()
  private let logHeaderLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic"
    view.backgroundColor = .systemBackground

    items = makeItems()
    applyLayoutMode()

    let stack = FKTabBarExampleSupport.makeRootStack(in: view, topInset: 16)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("FKTabBar basic integration (no controller)"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "This page shows the minimal setup and the two most common layout modes. FKTabBar is a UIView component and does not provide a TabBarController or paging controller wrapper."
      )
    )

    // Controls: layout mode
    modeControl.selectedSegmentIndex = layoutMode.rawValue
    modeControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.layoutMode = LayoutMode(rawValue: control.selectedSegmentIndex) ?? .fixedEqual
      self.applyLayoutMode()
      self.appendLog("layoutMode: \(self.layoutMode == .fixedEqual ? "fixedEqual" : "scrollable")")
    }, for: .valueChanged)
    stack.addArrangedSubview(modeControl)

    // Controls: notify toggle for programmatic selection
    notifyControl.selectedSegmentIndex = shouldNotifyProgrammaticSelection ? 0 : 1
    notifyControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.shouldNotifyProgrammaticSelection = control.selectedSegmentIndex == 0
      self.appendLog("programmatic notify: \(self.shouldNotifyProgrammaticSelection ? "on" : "off")")
    }, for: .valueChanged)
    stack.addArrangedSubview(notifyControl)

    tapEventPolicyControl.selectedSegmentIndex = 0
    tapEventPolicyControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.tabView.tapEventTriggerBehavior = control.selectedSegmentIndex == 0 ? .onceAfterSelection : .always
      self.appendLog("tapEventTriggerBehavior: \(control.selectedSegmentIndex == 0 ? "onceAfterSelection" : "always")")
    }, for: .valueChanged)
    stack.addArrangedSubview(tapEventPolicyControl)

    // Controls: enabled toggle for one tab
    let enabledRow = UIStackView()
    enabledRow.axis = .horizontal
    enabledRow.alignment = .center
    enabledRow.spacing = 10
    let enabledLabel = UILabel()
    enabledLabel.font = .preferredFont(forTextStyle: .body)
    enabledLabel.text = "Enable Tab #2"
    enabledRow.addArrangedSubview(enabledLabel)
    enabledRow.addArrangedSubview(UIView())
    enabledSwitch.isOn = isTab2Enabled
    enabledSwitch.addAction(UIAction { [weak self] action in
      guard let self, let sw = action.sender as? UISwitch else { return }
      self.isTab2Enabled = sw.isOn
      self.items = self.makeItems()
      self.tabView.reload(items: self.items, updatePolicy: .preserveSelection)
      self.appendLog("tab #2 enabled: \(self.isTab2Enabled)")
    }, for: .valueChanged)
    enabledRow.addArrangedSubview(enabledSwitch)
    stack.addArrangedSubview(enabledRow)

    // Actions
    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Random select") { [weak self] in
      self?.randomSelect()
    })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Reload items") { [weak self] in
      self?.reloadItems()
    })
    stack.addArrangedSubview(actions)

    let clearRow = UIStackView()
    clearRow.axis = .horizontal
    clearRow.spacing = 8
    clearRow.distribution = .fillEqually
    clearRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Clear log") { [weak self] in
      self?.clearLog()
    })
    clearRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select #2 (userTap)") { [weak self] in
      // Simulate a "userTap" semantic selection (still programmatic call).
      self?.tabView.setSelectedIndex(1, animated: true, notify: true, reason: .userTap)
    })
    stack.addArrangedSubview(clearRow)

    // Log
    logHeaderLabel.font = .preferredFont(forTextStyle: .headline)
    logHeaderLabel.text = "Event log"
    stack.addArrangedSubview(logHeaderLabel)

    logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.textColor = .label
    logView.isEditable = false
    logView.layer.cornerRadius = 12
    logView.textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
    logView.heightAnchor.constraint(equalToConstant: 220).isActive = true
    stack.addArrangedSubview(logView)

    // Attach tab bar (top pinned, like other pages in this example app)
    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 56),
    ])

    appendLog("ready: layout=\(layoutMode == .fixedEqual ? "fixedEqual" : "scrollable")")
  }

  // MARK: - FKTabBarDelegate

  func tabBar(_ tabBar: FKTabBar, shouldSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) -> Bool {
    appendLog("delegate.shouldSelect: \(index) enabled=\(item.isEnabled) reason=\(reason)")
    return true
  }

  func tabBar(_ tabBar: FKTabBar, willSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    appendLog("delegate.willSelect: \(index) (\(item.titleText ?? item.id)) reason=\(reason)")
  }

  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    appendLog("delegate.didSelect: \(index) (\(item.titleText ?? item.id)) reason=\(reason)")
  }

  func tabBar(_ tabBar: FKTabBar, didReselect item: FKTabBarItem, at index: Int) {
    appendLog("delegate.didReselect: \(index) (\(item.titleText ?? item.id))")
  }

  func tabBar(_ tabBar: FKTabBar, didRequestSelection item: FKTabBarItem, at index: Int) {
    appendLog("delegate.didRequestSelection: \(index) (\(item.titleText ?? item.id))")
  }

  // MARK: - Helpers

  private func makeItems() -> [FKTabBarItem] {
    var list = FKTabBarExampleSupport.makeItems(5)
    // Make it obvious which one is disabled.
    if list.indices.contains(1) {
      list[1].isEnabled = isTab2Enabled
      list[1].title = .init(normal: .init(text: isTab2Enabled ? "Explore" : "Explore (Disabled)"))
      list[1].accessibilityLabel = list[1].titleText
    }
    return list
  }

  private func applyLayoutMode() {
    switch layoutMode {
    case .fixedEqual:
      configuration.layout.isScrollable = false
      configuration.layout.widthMode = .fillEqually
      configuration.layout.itemSpacing = 0
      configuration.layout.contentInsets = .zero
    case .scrollable:
      configuration.layout.isScrollable = true
      configuration.layout.widthMode = .intrinsic
      configuration.layout.itemSpacing = 10
      configuration.layout.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
      configuration.layout.selectionScrollPosition = .center
    }
    tabView.configuration = configuration
  }

  private func randomSelect() {
    guard !items.isEmpty else { return }
    let index = Int.random(in: 0..<items.count)
    tabView.setSelectedIndex(index, animated: true, notify: shouldNotifyProgrammaticSelection, reason: .programmatic)
    appendLog("programmatic select: \(index) notify=\(shouldNotifyProgrammaticSelection)")
  }

  private func reloadItems() {
    // Simulate dynamic data refresh without adding any controller abstraction.
    isTab2Enabled.toggle()
    enabledSwitch.setOn(isTab2Enabled, animated: true)
    items = makeItems()
    tabView.reload(items: items, updatePolicy: .preserveSelection)
    appendLog("reload(items:), tab #2 enabled=\(isTab2Enabled)")
  }

  private func clearLog() {
    logView.text = ""
  }

  private func appendLog(_ line: String) {
    let ts = String(format: "%.3f", CACurrentMediaTime().truncatingRemainder(dividingBy: 1000))
    let newLine = "[\(ts)] \(line)\n"
    logView.text = (logView.text ?? "") + newLine
    let bottom = NSRange(location: max(0, (logView.text as NSString).length - 1), length: 1)
    logView.scrollRangeToVisible(bottom)
  }
}

