//
//  FKBarPresentationDemoViewController.swift
//  FKUIKitDemo
//
//  演示 `FKBarPresentation`：`FKBar` 选中条目后自锚点弹出 `FKPresentation`。
//

import UIKit
import FKButton
import FKBar
import FKBarPresentation
import FKPresentation

/// 演示 `FKBarPresentation`：条 + 浮层联动、闭包 / DataSource 两种内容来源、遮罩与 delegate 日志。
final class FKBarPresentationDemoViewController: UIViewController {

  private let barPresentation = FKBarPresentation()

  private enum ContentMode: Int {
    case closure = 0
    case dataSource = 1
  }

  private var contentMode: ContentMode = .closure

  private let logLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.text = "日志：选中条目后展示浮层；此处记录 FKBarPresentation / Bar 回调。"
    return label
  }()

  private let passthroughButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.title = "Passthrough（遮罩下仍可点）"
    config.cornerStyle = .medium
    config.baseBackgroundColor = .systemGray5
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    return UIButton(configuration: config)
  }()

  private let modeSegment = UISegmentedControl(items: ["闭包内容", "DataSource"])
  private let maskDismissSwitch = UISwitch()
  private let shadowSwitch = UISwitch()
  private let allowFlipSwitch = UISwitch()
  private let preferredHeightSwitch = UISwitch()

  private let heightSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 120
    s.maximumValue = 360
    s.value = 220
    return s
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBarPresentation"
    view.backgroundColor = .systemBackground

    barPresentation.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(barPresentation)

    barPresentation.delegate = self
    barPresentation.barDelegate = self
    barPresentation.presentationContent = { [weak self] _, index, item in
      guard let self, self.contentMode == .closure else { return nil }
      return self.makePanelContent(for: index, item: item)
    }

    modeSegment.selectedSegmentIndex = ContentMode.closure.rawValue
    modeSegment.addTarget(self, action: #selector(onModeChanged(_:)), for: .valueChanged)

    maskDismissSwitch.isOn = true
    shadowSwitch.isOn = true
    allowFlipSwitch.isOn = false
    preferredHeightSwitch.isOn = true
    maskDismissSwitch.addTarget(self, action: #selector(onConfigChanged), for: .valueChanged)
    shadowSwitch.addTarget(self, action: #selector(onConfigChanged), for: .valueChanged)
    allowFlipSwitch.addTarget(self, action: #selector(onConfigChanged), for: .valueChanged)
    preferredHeightSwitch.addTarget(self, action: #selector(onConfigChanged), for: .valueChanged)
    heightSlider.addTarget(self, action: #selector(onConfigChanged), for: .valueChanged)

    passthroughButton.addTarget(self, action: #selector(onPassthroughTapped), for: .touchUpInside)

    let panel = makeControlPanel()
    panel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(panel)

    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      barPresentation.topAnchor.constraint(equalTo: guide.topAnchor),
      barPresentation.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      barPresentation.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      panel.topAnchor.constraint(equalTo: barPresentation.bottomAnchor, constant: 16),
      panel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
      panel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
      panel.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor, constant: -16),
    ])

    barPresentation.backgroundColor = .white
    barPresentation.bar.backgroundColor = .white
    applyPresentationConfiguration()
    reloadBarItems()
  }

  // MARK: - Bar items

  private func reloadBarItems() {
    let bodyFont = UIFont.preferredFont(forTextStyle: .body)

    func textTab(_ id: String, title: String) -> FKBar.Item {
      var config = UIButton.Configuration.plain()
      config.title = title
      config.baseForegroundColor = .label
      config.contentInsets = .init(top: 8, leading: 14, bottom: 8, trailing: 14)
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
        var a = attrs
        a.font = bodyFont
        return a
      }
      return FKBar.Item(id: id, mode: .button(config), isSelected: false, selectionBehavior: .toggle)
    }

    /// `FKBar.Item.Mode.fkButton`：`FKButton` 胶囊样式。
    func fkCapsuleTab(_ id: String, title: String) -> FKBar.Item {
      var spec = FKBar.Item.FKButtonSpec()
      spec.content = FKButton.Content(kind: .textOnly)
      spec.setTitle(
        FKButton.Text(text: title, font: bodyFont, color: .label),
        for: .normal
      )
      spec.setTitle(
        FKButton.Text(text: title, font: bodyFont, color: .label),
        for: .selected
      )
      spec.setAppearance(
        FKButton.Appearance(
          corner: .capsule,
          backgroundColor: .systemGray6
        ),
        for: .normal
      )
      spec.setAppearance(
        FKButton.Appearance(
          corner: .capsule,
          borderWidth: 1,
          borderColor: .separator,
          backgroundColor: .white
        ),
        for: .selected
      )
      return FKBar.Item(id: id, mode: .fkButton(spec), isSelected: false, selectionBehavior: .toggle)
    }

    /// `FKButton`：标题 + **右侧**朝上的小箭头（`chevron.up`，尾随图槽）。
    func fkTabWithTrailingUpArrow(_ id: String, title: String) -> FKBar.Item {
      var spec = FKBar.Item.FKButtonSpec()
      spec.content = FKButton.Content(kind: .textAndImage(.trailing))
      spec.axis = .horizontal

      spec.setTitle(
        FKButton.Text(text: title, font: bodyFont, color: .label),
        for: .normal
      )
      spec.setTitle(
        FKButton.Text(text: title, font: bodyFont, color: .label),
        for: .selected
      )

      let arrowConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
      let arrowImage = FKButton.Image(
        systemName: "chevron.up",
        symbolConfiguration: arrowConfig,
        tintColor: .secondaryLabel,
        fixedSize: CGSize(width: 14, height: 14),
        spacingToTitle: 4
      )
      spec.setImage(arrowImage, for: .normal, slot: .trailing)
      spec.setImage(arrowImage, for: .selected, slot: .trailing)

      spec.setAppearance(
        FKButton.Appearance(
          corner: .capsule,
          backgroundColor: .systemGray6
        ),
        for: .normal
      )
      spec.setAppearance(
        FKButton.Appearance(
          corner: .capsule,
          borderWidth: 1,
          borderColor: .separator,
          backgroundColor: .white
        ),
        for: .selected
      )
      return FKBar.Item(id: id, mode: .fkButton(spec), isSelected: false, selectionBehavior: .toggle)
    }

    /// `FKBar.Item.Mode.customView`：自绘标签（Bar 外包 wrapper 并挂点击手势）。
    func customChipTab(_ id: String, title: String) -> FKBar.Item {
      let label = UILabel()
      label.text = title
      label.font = bodyFont
      label.textColor = .label
      label.backgroundColor = .systemGray6
      label.textAlignment = .center
      label.layer.cornerRadius = 8
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
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),
      ])

      return FKBar.Item(id: id, mode: .customView(pad), isSelected: false, selectionBehavior: .toggle)
    }

    let items: [FKBar.Item] = [
      textTab("tab-a", title: "Alpha"),
      textTab("tab-b", title: "Beta"),
      textTab("tab-c", title: "Gamma"),
      fkCapsuleTab("tab-fk1", title: "FK·甲"),
      fkCapsuleTab("tab-fk2", title: "FK·乙"),
      fkTabWithTrailingUpArrow("tab-fk-up", title: "FK·箭头"),
      customChipTab("tab-custom1", title: "自定义"),
      customChipTab("tab-custom2", title: "Chip"),
    ]
    barPresentation.reloadBarItems(items, animated: false)
    // 先全部未选中，再程序化选中首项，避免 `.toggle` 下「已选中再 select」被当成取消。
    barPresentation.bar.selectIndex(0, animated: false)
  }

  // MARK: - 浮层内容

  private func makePanelContent(for index: Int, item: FKBar.Item) -> UIView {
    let title = "条目 #\(index)\nid: \(String(item.id.prefix(6)))…\n\n可改选其他 Tab 或点遮罩关闭。"

    let container = UIView()
    container.backgroundColor = .white

    let hairline = UIView()
    hairline.backgroundColor = .separator
    hairline.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.text = title

    container.addSubview(hairline)
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)

    let lineHeight = 1 / max(UIScreen.main.scale, 1)
    NSLayoutConstraint.activate([
      hairline.topAnchor.constraint(equalTo: container.topAnchor),
      hairline.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      hairline.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      hairline.heightAnchor.constraint(equalToConstant: lineHeight),

      label.topAnchor.constraint(equalTo: hairline.bottomAnchor, constant: 16),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
    ])
    return container
  }

  // MARK: - 配置

  private func applyPresentationConfiguration() {
    var barCfg = FKBar.Configuration.default
    barCfg.itemSpacing = 8
    barCfg.contentInsets = .init(top: 10, leading: 12, bottom: 10, trailing: 12)
    barCfg.selectionScroll.isEnabled = true
    barCfg.appearance.backgroundColor = .white
    barCfg.appearance.alpha = 1

    var pres = FKPresentation.Configuration.default
    pres.appearance.backgroundColor = .white
    pres.appearance.alpha = 1
    pres.content.fallbackBackgroundColor = .white
    pres.mask.tapToDismissEnabled = maskDismissSwitch.isOn
    pres.mask.passthroughViews = [passthroughButton]
    pres.layout.allowFlipToAbove = allowFlipSwitch.isOn
    pres.layout.preferBelowSource = true
    pres.layout.verticalSpacing = 6
    pres.layout.horizontalAlignment = .center
    pres.layout.widthMode = .fullWidth
    pres.content.preferredHeight = preferredHeightSwitch.isOn ? CGFloat(heightSlider.value) : nil
    pres.appearance.cornerRadius = 14
    pres.appearance.maskedCorners = [
      .layerMinXMaxYCorner,
      .layerMaxXMaxYCorner,
    ]
    if shadowSwitch.isOn {
      pres.appearance.shadow = .init(
        color: .black,
        opacity: 0.16,
        offset: CGSize(width: 0, height: 3),
        radius: 8,
        edgeStyle: .followsPresentation
      )
    } else {
      pres.appearance.shadow = nil
    }

    barPresentation.configuration = FKBarPresentation.Configuration(
      bar: barCfg,
      presentation: pres,
      behavior: .init(
        presentsOnSelection: true,
        dismissesWhenSelectionCleared: true,
        dismissBeforeChangingSelection: true,
        ignoresRepeatedSelectWhilePresented: true
      ),
      presentationHost: .automatic
    )

    syncDataSourceBinding()
  }

  private func syncDataSourceBinding() {
    switch contentMode {
    case .closure:
      barPresentation.dataSource = nil
      barPresentation.presentationContent = { [weak self] _, index, item in
        guard let self else { return nil }
        return self.makePanelContent(for: index, item: item)
      }
    case .dataSource:
      barPresentation.presentationContent = nil
      barPresentation.dataSource = self
    }
  }

  @objc private func onModeChanged(_ sender: UISegmentedControl) {
    contentMode = ContentMode(rawValue: sender.selectedSegmentIndex) ?? .closure
    syncDataSourceBinding()
    appendLog("内容来源 → \(contentMode == .closure ? "闭包" : "DataSource")")
  }

  @objc private func onConfigChanged() {
    applyPresentationConfiguration()
  }

  @objc private func onPassthroughTapped() {
    appendLog("Passthrough 按钮被点击（遮罩未拦截）")
  }

  private func makeControlPanel() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 12

    let tip = UILabel()
    tip.numberOfLines = 0
    tip.font = .preferredFont(forTextStyle: .footnote)
    tip.textColor = .tertiaryLabel
    tip.text = "说明：浮层锚定为当前选中的条目标签，进入页面后会自动选中首项并弹出浮层。"

    stack.addArrangedSubview(tip)
    stack.addArrangedSubview(modeSegment)
    stack.addArrangedSubview(makeToggleRow(title: "遮罩点击关闭", switchView: maskDismissSwitch))
    stack.addArrangedSubview(makeToggleRow(title: "浮层阴影", switchView: shadowSwitch))
    stack.addArrangedSubview(makeToggleRow(title: "允许翻到锚点上方", switchView: allowFlipSwitch))
    stack.addArrangedSubview(makeToggleRow(title: "固定浮层高度（滑块）", switchView: preferredHeightSwitch))
    stack.addArrangedSubview(makeSliderRow(title: "高度", slider: heightSlider))
    stack.addArrangedSubview(passthroughButton)

    let dismissBtn = makeFilledButton(title: "代码关闭浮层", action: #selector(onDismissPanel))
    stack.addArrangedSubview(dismissBtn)

    let reloadBtn = makeFilledButton(title: "重置 Bar 条目", action: #selector(onReloadBar))
    stack.addArrangedSubview(reloadBtn)

    logLabel.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(logLabel)
    return stack
  }

  private func makeToggleRow(title: String, switchView: UISwitch) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    row.addArrangedSubview(label)
    row.addArrangedSubview(UIView())
    row.addArrangedSubview(switchView)
    return row
  }

  private func makeSliderRow(title: String, slider: UISlider) -> UIView {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    row.addArrangedSubview(label)
    row.addArrangedSubview(slider)
    return row
  }

  private func makeFilledButton(title: String, action: Selector) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.baseBackgroundColor = .systemGray5
    config.baseForegroundColor = .label
    let b = UIButton(configuration: config)
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }

  @objc private func onDismissPanel() {
    barPresentation.dismissPresentation(animated: true, completion: nil)
    appendLog("调用 dismissPresentation(animated:)")
  }

  @objc private func onReloadBar() {
    reloadBarItems()
    appendLog("reloadBarItems（Alpha 默认选中）")
  }

  private func appendLog(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    let prefix = logLabel.text ?? ""
    logLabel.text = prefix + "\n[\(stamp)] \(line)"
  }

  private static let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
  }()
}

// MARK: - FKBarPresentationDelegate

extension FKBarPresentationDemoViewController: FKBarPresentationDelegate {
  func barPresentation(_ barPresentation: FKBarPresentation, shouldPresentFor item: FKBar.Item, at index: Int) -> Bool {
    appendLog("shouldPresent index=\(index) id=\(String(item.id.prefix(6)))… → true")
    return true
  }

  func barPresentation(_ barPresentation: FKBarPresentation, willPresentFor item: FKBar.Item, at index: Int) {
    appendLog("willPresent index=\(index)")
  }

  func barPresentation(_ barPresentation: FKBarPresentation, didPresentFor item: FKBar.Item, at index: Int) {
    appendLog("didPresent index=\(index)")
  }

  func barPresentation(_ barPresentation: FKBarPresentation, willDismissPresentation reason: FKBarPresentation.PresentationDismissReason) {
    appendLog("willDismiss reason=\(reason)")
  }

  func barPresentation(_ barPresentation: FKBarPresentation, didDismissPresentation reason: FKBarPresentation.PresentationDismissReason) {
    appendLog("didDismiss reason=\(reason)")
  }
}

// MARK: - FKBarDelegate（转发演示）

extension FKBarPresentationDemoViewController: FKBarDelegate {
  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int) {
    appendLog("bar.didSelect index=\(index)")
  }

  func bar(_ bar: FKBar, didDeselect sender: UIView, for item: FKBar.Item, at index: Int) {
    appendLog("bar.didDeselect index=\(index)")
  }
}

// MARK: - FKBarPresentationDataSource

extension FKBarPresentationDemoViewController: FKBarPresentationDataSource {
  func barPresentation(_ barPresentation: FKBarPresentation, presentationViewForItemAt index: Int) -> UIView? {
    guard contentMode == .dataSource else { return nil }
    guard let item = barPresentation.bar.loadedItems[safe: index] else { return nil }
    return makePanelContent(for: index, item: item)
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    guard indices.contains(index) else { return nil }
    return self[index]
  }
}
