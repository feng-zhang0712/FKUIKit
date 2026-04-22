import UIKit
import FKUIKit

/// UITableView scenario page.
///
/// - Notes:
///   - This file intentionally keeps only the core integration logic (copy-ready).
///   - Each mode demonstrates one key capability of FKSwipeAction.
final class FKSwipeActionTableScenarioViewController: UITableViewController {
  enum Mode {
    case tableSingleButton
    case tableMultiButtons
    case rightSwipe
    case textOnly
    case iconOnly
    case iconTop
    case iconLeading
    case gradientBackground
    case customStyle
    case exclusiveOpen
    case multipleOpen
    case tapToClose
    case customThreshold
    case stateCallback
    case dynamicToggle
    case darkMode
    case rotation
  }

  private let mode: Mode
  private var items: [String] = []
  private var isSwipeEnabled = true
  private let callbackLabel = UILabel()
  private let headerContainer = UIView()
  private var lastHeaderWidth: CGFloat = 0

  init(mode: Mode) {
    self.mode = mode
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Basic UI: Auto Layout, rotation friendly, light/dark compatible.
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 56
    tableView.cellLayoutMarginsFollowReadableWidth = true

    // Demo data: keep it simple and readable.
    items = (0..<30).map { "Row \($0) (swipe left/right)" }

    // Header description / callback output (shown when needed).
    callbackLabel.numberOfLines = 0
    callbackLabel.font = .preferredFont(forTextStyle: .footnote)
    callbackLabel.textColor = .secondaryLabel
    callbackLabel.textAlignment = .left
    callbackLabel.text = makeHeaderText()
    configureHeaderIfNeeded()
    updateHeaderLayoutIfNeeded(force: true)

    // Screen title & appearance.
    title = makeTitle()
    if mode == .darkMode {
      // Dark mode demo: force dark for this screen (does not affect global setting).
      overrideUserInterfaceStyle = .dark
    }

    // Dynamic toggle: demonstrate enabling/disabling at runtime.
    if mode == .dynamicToggle {
      navigationItem.rightBarButtonItem = UIBarButtonItem(
        title: "Disable Swipe",
        style: .plain,
        target: self,
        action: #selector(toggleSwipe)
      )
    }

    // Key line: enable swipe actions for UITableView (no cell subclassing required).
    tableView.fk_enableSwipeActions { [weak self] indexPath in
      guard let self else { return FKSwipeActionConfiguration() }
      return self.makeConfiguration(for: indexPath)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // Avoid rebuilding tableHeaderView on every layout pass.
    // Only update when width changes (e.g. rotation) to prevent layout loops and memory growth.
    updateHeaderLayoutIfNeeded(force: false)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = items[indexPath.row]
    config.secondaryText = "Tip: buttons are rendered by FKSwipeAction without modifying your cell."
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.selectionStyle = .none
    return cell
  }

  // MARK: - 动态开关演示

  @objc private func toggleSwipe() {
    isSwipeEnabled.toggle()
    // Key line: dynamically enable/disable swipe actions.
    tableView.fk_setSwipeActionsEnabled(isSwipeEnabled)
    navigationItem.rightBarButtonItem?.title = isSwipeEnabled ? "Disable Swipe" : "Enable Swipe"
    callbackLabel.text = "Swipe: \(isSwipeEnabled ? "Enabled" : "Disabled")\n\n" + makeHeaderText()
    updateHeaderLayoutIfNeeded(force: true)
  }

  // MARK: - Configuration builder (copy-ready)

  private func makeConfiguration(for indexPath: IndexPath) -> FKSwipeActionConfiguration {
    let defaultRight = [
      FKSwipeActionButton(
        id: "delete",
        title: "Delete",
        icon: UIImage(systemName: "trash.fill"),
        background: .color(.systemRed),
        layout: .iconTop,
        width: 86,
        cornerRadius: 12
      ) {
        // Demo only: no actual deletion is performed here.
      }
    ]

    switch mode {
    case .tableSingleButton:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), width: 84) {}
        ],
        allowedDirections: [.left]
      )

    case .tableMultiButtons:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), width: 84) {},
          FKSwipeActionButton(id: "pin", title: "Pin", background: .color(.systemOrange), width: 84) {},
          FKSwipeActionButton(id: "mark", title: "Mark", background: .color(.systemBlue), width: 84) {},
        ],
        allowedDirections: [.left]
      )

    case .rightSwipe:
      // Right swipe: configure leftActions and restrict direction to `.right`.
      return FKSwipeActionConfiguration(
        leftActions: [
          FKSwipeActionButton(id: "reply", title: "Reply", background: .color(.systemGreen), width: 84) {},
          FKSwipeActionButton(id: "call", title: "Call", background: .color(.systemBlue), width: 84) {},
        ],
        allowedDirections: [.right]
      )

    case .textOnly:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), layout: .title, width: 84) {},
          FKSwipeActionButton(id: "more", title: "More", background: .color(.systemGray), layout: .title, width: 84) {},
        ]
      )

    case .iconOnly:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "trash", title: nil, icon: UIImage(systemName: "trash.fill"), background: .color(.systemRed), layout: .icon, width: 72) {},
          FKSwipeActionButton(id: "flag", title: nil, icon: UIImage(systemName: "flag.fill"), background: .color(.systemOrange), layout: .icon, width: 72) {},
        ]
      )

    case .iconTop:
      return FKSwipeActionConfiguration(
        rightActions: defaultRight,
        allowedDirections: [.left]
      )

    case .iconLeading:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "share",
            title: "Share",
            icon: UIImage(systemName: "square.and.arrow.up"),
            background: .color(.systemIndigo),
            layout: .iconLeading,
            width: 108,
            cornerRadius: 14
          ) {}
        ],
        allowedDirections: [.left]
      )

    case .gradientBackground:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "gradient1",
            title: "Gradient",
            icon: UIImage(systemName: "sparkles"),
            background: .verticalGradient(top: .systemPurple, bottom: .systemPink),
            layout: .iconTop,
            width: 86,
            cornerRadius: 14
          ) {},
          FKSwipeActionButton(
            id: "gradient2",
            title: "Gradient",
            icon: UIImage(systemName: "bolt.fill"),
            background: .horizontalGradient(leading: .systemTeal, trailing: .systemBlue),
            layout: .iconLeading,
            width: 100,
            cornerRadius: 14
          ) {},
        ]
      )

    case .customStyle:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "vip",
            title: "VIP",
            icon: UIImage(systemName: "crown.fill"),
            background: .color(.black),
            font: .systemFont(ofSize: 13, weight: .heavy),
            titleColor: .systemYellow,
            layout: .iconLeading,
            width: 108,
            cornerRadius: 18
          ) {},
          FKSwipeActionButton(
            id: "note",
            title: "Note",
            icon: UIImage(systemName: "pencil.circle.fill"),
            background: .color(.systemGray2),
            font: .systemFont(ofSize: 14, weight: .semibold),
            titleColor: .white,
            layout: .iconTop,
            width: 90,
            cornerRadius: 18
          ) {},
        ]
      )

    case .exclusiveOpen:
      return FKSwipeActionConfiguration(
        rightActions: defaultRight,
        allowsOnlyOneOpen: true
      )

    case .multipleOpen:
      // Allow multiple cells to remain open.
      return FKSwipeActionConfiguration(
        rightActions: defaultRight,
        allowsOnlyOneOpen: false
      )

    case .tapToClose:
      // Tap anywhere to close the opened cell.
      return FKSwipeActionConfiguration(
        rightActions: defaultRight,
        tapToClose: true
      )

    case .customThreshold:
      // Custom threshold: requires a longer swipe distance to snap open.
      return FKSwipeActionConfiguration(
        rightActions: defaultRight,
        openThreshold: 120
      )

    case .stateCallback:
      // State callback: show events in the header label.
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), width: 84) {},
          FKSwipeActionButton(id: "more", title: "More", background: .color(.systemGray), width: 84) {},
        ],
        onEvent: { [weak self] event in
          guard let self else { return }
          DispatchQueue.main.async {
            self.callbackLabel.text = self.makeHeaderText() + "\n\nLast event: \(self.describe(event))"
            self.updateHeaderLayoutIfNeeded(force: true)
          }
        }
      )

    case .dynamicToggle:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), width: 84) {},
          FKSwipeActionButton(id: "pin", title: "Pin", background: .color(.systemOrange), width: 84) {},
        ]
      )

    case .darkMode:
      return FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), width: 84, cornerRadius: 14) {},
          FKSwipeActionButton(id: "mark", title: "Mark", background: .color(.systemBlue), width: 84, cornerRadius: 14) {},
        ]
      )

    case .rotation:
      // Rotation: FKSwipeAction uses frame + autoresizing for buttons, so it adapts automatically.
      return FKSwipeActionConfiguration(rightActions: defaultRight)
    }
  }

  // MARK: - Text & helpers

  private func makeTitle() -> String {
    switch mode {
    case .tableSingleButton: return "UITableView: Single Action"
    case .tableMultiButtons: return "UITableView: Multiple Actions"
    case .rightSwipe: return "Right Swipe: Left Actions"
    case .textOnly: return "Button: Text Only"
    case .iconOnly: return "Button: Icon Only"
    case .iconTop: return "Button: Icon + Title (Vertical)"
    case .iconLeading: return "Button: Icon + Title (Horizontal)"
    case .gradientBackground: return "Button: Gradient Background"
    case .customStyle: return "Button: Custom Style"
    case .exclusiveOpen: return "Mutual Exclusion (Single Open)"
    case .multipleOpen: return "Allow Multiple Open"
    case .tapToClose: return "Tap to Close"
    case .customThreshold: return "Custom Open Threshold"
    case .stateCallback: return "State Callback"
    case .dynamicToggle: return "Dynamic Toggle"
    case .darkMode: return "Dark Mode"
    case .rotation: return "Rotation"
    }
  }

  private func makeHeaderText() -> String {
    switch mode {
    case .dynamicToggle:
      return "Demo: use the top-right button to enable/disable swipe.\nNote: scrolling and taps still work when disabled."
    case .customThreshold:
      return "Demo: openThreshold = 120.\nNote: you must swipe further to snap open after release."
    case .stateCallback:
      return "Demo: onEvent observes begin/end/tap.\nNote: the last event is printed here."
    case .rotation:
      return "Demo: rotate the device (portrait/landscape).\nNote: button layout and reveal width adapt automatically."
    case .darkMode:
      return "Demo: force dark mode on this screen.\nNote: colors adapt automatically when using system colors."
    default:
      return "Tip: swipe left/right to reveal actions.\nNote: actions are inserted behind the cell content without modifying your cell."
    }
  }

  private func configureHeaderIfNeeded() {
    guard tableView.tableHeaderView == nil else { return }
    headerContainer.backgroundColor = .clear
    callbackLabel.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(callbackLabel)
    NSLayoutConstraint.activate([
      callbackLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
      callbackLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
      callbackLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
      callbackLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),
    ])
    tableView.tableHeaderView = headerContainer
  }

  private func updateHeaderLayoutIfNeeded(force: Bool) {
    let width = view.bounds.width
    if !force, abs(width - lastHeaderWidth) < 0.5 { return }
    lastHeaderWidth = width
    let size = headerContainer.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
    tableView.tableHeaderView = headerContainer
  }

  private func describe(_ event: FKSwipeActionConfiguration.Event) -> String {
    switch event {
    case .willBeginSwipe(let indexPath, let direction):
      return "willBeginSwipe indexPath=\(indexPath) direction=\(direction)"
    case .didEndSwipe(let indexPath, let isOpen, let direction):
      return "didEndSwipe indexPath=\(indexPath) isOpen=\(isOpen) direction=\(String(describing: direction))"
    case .didTapAction(let indexPath, let actionID):
      return "didTapAction indexPath=\(indexPath) actionID=\(actionID)"
    }
  }
}

