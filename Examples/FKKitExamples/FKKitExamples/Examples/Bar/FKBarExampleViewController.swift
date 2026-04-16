//
//  FKBarExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

/// 演示 `FKBar`：全宽横向滚动条（紧贴导航栏下方）、多种条目类型与调试面板。
final class FKBarExampleViewController: UIViewController {

  private let bar = FKBar()
  private var counter: Int = 0
  private var usesLargeContent: Bool = false
  private var usesTightInsets: Bool = false
  private var usesTightSpacing: Bool = false
  private var currentItems: [FKBar.Item] = []

  private enum CallbackMode: Int {
    case delegate = 0
    case actionHandler = 1
    case both = 2
  }

  private var callbackMode: CallbackMode = .both
  private let tapLogLabel = UILabel()
  private let reloadLogLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "FKBar"
    view.backgroundColor = .systemBackground

    setupUI()
    applyBarConfig()
    applyCallbackMode()
    reloadBar(animated: false)
  }

  // MARK: - UI

  private func setupUI() {
    bar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bar)

    let actions = makeActionsPanel()
    actions.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(actions)

    let guide = view.safeAreaLayoutGuide
    // Bar：与屏幕同宽（leading/trailing 贴 view），高度由 intrinsicContentSize 决定。
    NSLayoutConstraint.activate([
      bar.topAnchor.constraint(equalTo: guide.topAnchor),
      bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      actions.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 16),
      actions.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
      actions.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
      actions.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor, constant: -16),
    ])

    bar.backgroundColor = .secondarySystemBackground

    tapLogLabel.numberOfLines = 0
    tapLogLabel.font = .preferredFont(forTextStyle: .footnote)
    tapLogLabel.textColor = .secondaryLabel
    tapLogLabel.text = "点击条目后在此显示回调与条目 id。"

    reloadLogLabel.numberOfLines = 0
    reloadLogLabel.font = .preferredFont(forTextStyle: .caption2)
    reloadLogLabel.textColor = .tertiaryLabel
    reloadLogLabel.text = "didReloadItems：—"
  }

  private func makeActionsPanel() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.distribution = .fill
    stack.spacing = 12

    let modeSegment = UISegmentedControl(items: ["Delegate", "Item", "Both"])
    modeSegment.selectedSegmentIndex = CallbackMode.both.rawValue
    modeSegment.addTarget(self, action: #selector(onCallbackModeChanged(_:)), for: .valueChanged)
    stack.addArrangedSubview(modeSegment)

    tapLogLabel.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(tapLogLabel)

    reloadLogLabel.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(reloadLogLabel)

    stack.addArrangedSubview(makeRow(
      makeButton("Reload", action: #selector(onReload)),
      makeButton("+1 Item", action: #selector(onAddItem)),
      makeButton("Shuffle", action: #selector(onShuffle))
    ))

    stack.addArrangedSubview(makeRow(
      makeButton("Insets", action: #selector(onToggleInsets)),
      makeButton("Spacing", action: #selector(onToggleSpacing)),
      makeButton("Font", action: #selector(onToggleFont))
    ))

    let tip = UILabel()
    tip.numberOfLines = 0
    tip.textColor = .secondaryLabel
    tip.font = .preferredFont(forTextStyle: .footnote)
    tip.text =
      "调试：可在 `FKBar` / `handleItemTap` / `reloadItems` 打断点。\n" +
      "条目含：系统 UIButton.Configuration、FKButton、自定义 UIView。"
    stack.addArrangedSubview(tip)

    return stack
  }

  private func makeRow(_ views: UIView...) -> UIView {
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.alignment = .fill
    row.distribution = .fillEqually
    row.spacing = 12
    return row
  }

  private func makeButton(_ title: String, action: Selector) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.baseBackgroundColor = .systemBlue
    config.baseForegroundColor = .white
    config.cornerStyle = .medium

    let button = UIButton(configuration: config)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  // MARK: - Bar config & data

  private func applyBarConfig() {
    let spacing: CGFloat = usesTightSpacing ? 4 : 10
    let insets: NSDirectionalEdgeInsets = usesTightInsets
      ? .init(top: 6, leading: 8, bottom: 6, trailing: 8)
      : .init(top: 12, leading: 12, bottom: 12, trailing: 12)

    bar.configuration = FKBar.Configuration(
      itemSpacing: spacing,
      contentInsets: insets,
      alwaysBounceHorizontal: true
    )
  }

  private func reloadBar(animated: Bool) {
    let items = makeItems()
    currentItems = items
    bar.reloadItems(items, animated: animated)
  }

  private func makeItems() -> [FKBar.Item] {
    let font: UIFont = usesLargeContent
      ? .preferredFont(forTextStyle: .title3)
      : .preferredFont(forTextStyle: .body)

    func textButton(_ title: String, tint: UIColor) -> FKBar.Item {
      var config = UIButton.Configuration.plain()
      config.title = title
      config.baseForegroundColor = tint
      config.contentInsets = .init(top: 6, leading: 10, bottom: 6, trailing: 10)
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
        var a = attrs
        a.font = font
        return a
      }
      return FKBar.Item(mode: .button(config))
    }

    func iconButton(_ systemName: String, tint: UIColor) -> FKBar.Item {
      var config = UIButton.Configuration.plain()
      config.image = UIImage(systemName: systemName)
      config.baseForegroundColor = tint
      config.contentInsets = .init(top: 6, leading: 10, bottom: 6, trailing: 10)
      return FKBar.Item(mode: .button(config))
    }

    func fkPill(_ title: String) -> FKBar.Item {
      var spec = FKBar.Item.FKButtonSpec()
      spec.content = FKButton.Content(kind: .textOnly)
      spec.setTitle(
        FKButton.Text(text: title, font: font, color: .label),
        for: .normal
      )
      spec.setTitle(
        FKButton.Text(text: title, font: font, color: .systemOrange),
        for: .selected
      )
      spec.setAppearance(
        FKButton.Appearance(
          cornerStyle: .init(corner: .capsule),
          backgroundColor: .secondarySystemFill,
          contentInsets: .init(top: 6, leading: 10, bottom: 6, trailing: 10)
        ),
        for: .normal
      )
      spec.setAppearance(
        FKButton.Appearance(
          cornerStyle: .init(corner: .capsule),
          border: .init(width: 1, color: .systemOrange),
          backgroundColor: UIColor.systemOrange.withAlphaComponent(0.12),
          contentInsets: .init(top: 6, leading: 10, bottom: 6, trailing: 10)
        ),
        for: .selected
      )
      return FKBar.Item(mode: .fkButton(spec))
    }

    func customPill(_ text: String, color: UIColor) -> FKBar.Item {
      let label = UILabel()
      label.text = text
      label.font = font
      label.textColor = color
      label.backgroundColor = color.withAlphaComponent(0.12)
      label.textAlignment = .center
      label.layer.cornerRadius = 10
      label.layer.cornerCurve = .continuous
      label.layer.masksToBounds = true
      label.setContentHuggingPriority(.required, for: .horizontal)
      label.setContentCompressionResistancePriority(.required, for: .horizontal)

      let pad = UIView()
      pad.translatesAutoresizingMaskIntoConstraints = false
      label.translatesAutoresizingMaskIntoConstraints = false
      pad.addSubview(label)
      NSLayoutConstraint.activate([
        label.topAnchor.constraint(equalTo: pad.topAnchor),
        label.bottomAnchor.constraint(equalTo: pad.bottomAnchor),
        label.leadingAnchor.constraint(equalTo: pad.leadingAnchor),
        label.trailingAnchor.constraint(equalTo: pad.trailingAnchor),
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      ])

      return FKBar.Item(mode: .customView(pad))
    }

    let n = max(3, (counter % 10) + 3)
    var result: [FKBar.Item] = []

    result.append(iconButton("line.3.horizontal.decrease.circle", tint: .systemBlue))
    result.append(textButton("Filter \(counter)", tint: .systemBlue))
    result.append(fkPill("FKButton"))

    for i in 0..<n {
      if i % 3 == 0 {
        result.append(customPill("Tag \(i)", color: .systemGreen))
      } else if i % 3 == 1 {
        result.append(textButton("Item \(i)", tint: .label))
      } else {
        result.append(iconButton("star", tint: .systemOrange))
      }
    }

    var disabled = textButton("Disabled", tint: .secondaryLabel)
    disabled.isEnabled = false
    result.append(disabled)

    if callbackMode == .actionHandler || callbackMode == .both {
      for i in 0..<result.count {
        var item = result[i]
        item.actionHandler = { [weak self] tapped in
          let idx = self?.currentItems.firstIndex(where: { $0.id == tapped.id })
          self?.logTap(source: "item.actionHandler", item: tapped, index: idx)
        }
        result[i] = item
      }
    }

    return result
  }

  private func applyCallbackMode() {
    switch callbackMode {
    case .delegate, .both:
      bar.delegate = self
    case .actionHandler:
      bar.delegate = nil
    }
  }

  private func logTap(source: String, item: FKBar.Item, index: Int?) {
    let shortID = String(item.id.prefix(8))
    let idxText = index.map { String($0) } ?? "-"
    tapLogLabel.text =
      "来源：\(source)\n" +
      "id: \(shortID)…\n" +
      "index: \(idxText)\n" +
      "selected: \(item.isSelected)"
  }

  // MARK: - Actions

  @objc private func onReload() {
    reloadBar(animated: true)
  }

  @objc private func onAddItem() {
    counter += 1
    reloadBar(animated: true)
  }

  @objc private func onShuffle() {
    counter += 1
    reloadBar(animated: true)
  }

  @objc private func onToggleInsets() {
    usesTightInsets.toggle()
    applyBarConfig()
    reloadBar(animated: true)
  }

  @objc private func onToggleSpacing() {
    usesTightSpacing.toggle()
    applyBarConfig()
    reloadBar(animated: true)
  }

  @objc private func onToggleFont() {
    usesLargeContent.toggle()
    reloadBar(animated: true)
  }

  @objc private func onCallbackModeChanged(_ sender: UISegmentedControl) {
    callbackMode = CallbackMode(rawValue: sender.selectedSegmentIndex) ?? .both
    applyCallbackMode()
    reloadBar(animated: true)
  }
}

// MARK: - FKBarDelegate

extension FKBarExampleViewController: FKBarDelegate {

  func bar(_ bar: FKBar, didReloadItems items: [FKBar.Item]) {
    reloadLogLabel.text = "didReloadItems：\(items.count) 条"
  }

  func bar(
    _ bar: FKBar,
    prepare sender: UIView,
    for item: FKBar.Item,
    at index: Int
  ) {
    if let button = sender as? UIButton {
      if button.configurationUpdateHandler == nil {
        button.configurationUpdateHandler = { [weak bar] b in
          guard let bar else { return }
          let idx = b.tag
          guard let itemView = bar.sourceView(forItemAt: idx),
                let itemButton = itemView as? UIButton else { return }
          guard var cfg = itemButton.configuration else { return }
          cfg.background.backgroundColor = itemButton.isSelected
            ? UIColor.systemBlue.withAlphaComponent(0.16)
            : .clear
          cfg.baseForegroundColor = itemButton.isEnabled ? .label : .secondaryLabel
          itemButton.configuration = cfg
          itemButton.alpha = itemButton.isEnabled ? 1.0 : 0.45
        }
      }
      guard var config = button.configuration else { return }
      config.background.backgroundColor = item.isSelected
        ? UIColor.systemBlue.withAlphaComponent(0.16)
        : .clear
      config.baseForegroundColor = item.isEnabled ? .label : .secondaryLabel
      button.configuration = config
      button.alpha = item.isEnabled ? 1.0 : 0.45
      return
    }

    sender.layer.cornerRadius = 10
    sender.layer.cornerCurve = .continuous
    sender.alpha = item.isEnabled ? (item.isSelected ? 1.0 : 0.88) : 0.45
    sender.backgroundColor = item.isSelected
      ? UIColor.systemBlue.withAlphaComponent(0.12)
      : .clear
  }

  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int) {
    bar.refreshPreparedAppearance()
    logTap(source: "delegate.didSelect", item: item, index: index)
    if let button = sender as? UIButton {
      UIView.animate(withDuration: 0.12, animations: {
        button.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
      }) { _ in
        UIView.animate(withDuration: 0.12) { button.transform = .identity }
      }
    } else {
      UIView.animate(withDuration: 0.12, animations: {
        sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
      }) { _ in
        UIView.animate(withDuration: 0.12) { sender.transform = .identity }
      }
    }
  }

  func bar(
    _ bar: FKBar,
    didDeselect sender: UIView,
    for item: FKBar.Item,
    at index: Int
  ) {
    bar.refreshPreparedAppearance()
    logTap(source: "delegate.didDeselect", item: item, index: index)
  }
}
