//
//  FKBarPresentationExampleViewController.swift
//  FKKitExamples
//
//  Example for `FKBarPresentation`: select an item in `FKBar` to present an anchored `FKPresentation`.
//

import UIKit
import FKUIKit

/// Example for `FKBarPresentation`: bar + panel, closure vs data source content, mask behavior, and callback logs.
final class FKBarPresentationExampleViewController: UIViewController {

  private let barPresentation = FKBarPresentation()

  private enum ContentMode: Int {
    case closure = 0
    case dataSource = 1
  }

  private var contentMode: ContentMode = .closure

  /// Example logs: read-only & scrollable to avoid unbounded growth and slowdowns.
  private let logTextView: UITextView = {
    let tv = UITextView()
    tv.isEditable = false
    tv.isSelectable = false
    tv.isScrollEnabled = true
    tv.backgroundColor = .clear
    tv.textColor = .secondaryLabel
    tv.font = .preferredFont(forTextStyle: .footnote)
    tv.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    tv.textContainer.lineFragmentPadding = 0
    tv.text = "Log:"
    tv.translatesAutoresizingMaskIntoConstraints = false
    return tv
  }()

  private let maxLogCharacters: Int = 6000

  private let passthroughButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.title = "Passthrough (tap-through on mask)"
    config.cornerStyle = .medium
    config.baseBackgroundColor = .systemGray5
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    return UIButton(configuration: config)
  }()

  private let modeSegment = UISegmentedControl(items: ["Closure", "DataSource"])
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

    let panelScrollView = UIScrollView()
    panelScrollView.translatesAutoresizingMaskIntoConstraints = false
    panelScrollView.alwaysBounceVertical = true
    panelScrollView.showsVerticalScrollIndicator = true
    view.addSubview(panelScrollView)
    panelScrollView.addSubview(panel)

    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      barPresentation.topAnchor.constraint(equalTo: guide.topAnchor),
      barPresentation.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      barPresentation.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      panelScrollView.topAnchor.constraint(equalTo: barPresentation.bottomAnchor, constant: 16),
      panelScrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      panelScrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      panelScrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

      panel.topAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.topAnchor),
      panel.leadingAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
      panel.trailingAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.trailingAnchor, constant: -16),
      panel.bottomAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.bottomAnchor, constant: -16),
      panel.widthAnchor.constraint(equalTo: panelScrollView.frameLayoutGuide.widthAnchor, constant: -32),
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

    /// `FKBar.Item.Mode.fkButton`: `FKButton` capsule style.
    func fkCapsuleTab(_ id: String, title: String) -> FKBar.Item {
      var spec = FKBar.Item.FKButtonSpec()
      spec.content = FKButton.Content(kind: .textOnly)
      spec.setTitle(
        FKButton.LabelAttributes(text: title, font: bodyFont, color: .label),
        for: .normal
      )
      spec.setTitle(
        FKButton.LabelAttributes(text: title, font: bodyFont, color: .label),
        for: .selected
      )
      spec.setAppearance(
        FKButton.Appearance(
          cornerStyle: .init(corner: .capsule),
          backgroundColor: .systemGray6
        ),
        for: .normal
      )
      spec.setAppearance(
        FKButton.Appearance(
          cornerStyle: .init(corner: .capsule),
          border: .init(width: 1, color: .separator),
          backgroundColor: .white
        ),
        for: .selected
      )
      return FKBar.Item(id: id, mode: .fkButton(spec), isSelected: false, selectionBehavior: .toggle)
    }

    /// `FKButton`: title + a trailing up chevron (`chevron.up`).
    func fkTabWithTrailingUpArrow(_ id: String, title: String) -> FKBar.Item {
      var spec = FKBar.Item.FKButtonSpec()
      spec.content = FKButton.Content(kind: .textAndImage(.trailing))
      spec.axis = .horizontal

      spec.setTitle(
        FKButton.LabelAttributes(text: title, font: bodyFont, color: .label),
        for: .normal
      )
      spec.setTitle(
        FKButton.LabelAttributes(text: title, font: bodyFont, color: .label),
        for: .selected
      )

      let arrowConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
      let arrowImage = FKButton.ImageAttributes(
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
          cornerStyle: .init(corner: .capsule),
          backgroundColor: .systemGray6
        ),
        for: .normal
      )
      spec.setAppearance(
        FKButton.Appearance(
          cornerStyle: .init(corner: .capsule),
          border: .init(width: 1, color: .separator),
          backgroundColor: .white
        ),
        for: .selected
      )
      return FKBar.Item(id: id, mode: .fkButton(spec), isSelected: false, selectionBehavior: .toggle)
    }

    /// `FKBar.Item.Mode.customView`: a custom chip view (wrapped by the bar with a tap gesture).
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
      fkCapsuleTab("tab-fk1", title: "FK·A"),
      fkCapsuleTab("tab-fk2", title: "FK·B"),
      fkTabWithTrailingUpArrow("tab-fk-up", title: "FK·Chevron"),
      customChipTab("tab-custom1", title: "Custom"),
      customChipTab("tab-custom2", title: "Chip"),
    ]
    barPresentation.reloadBarItems(items, animated: false)
    // Start from all-unselected, then programmatically select the first item.
    barPresentation.bar.selectIndex(0, animated: false)
  }

  // MARK: - Panel content

  private func makePanelContent(for index: Int, item: FKBar.Item) -> UIView {
    let title = "Item #\(index)\nid: \(String(item.id.prefix(6)))…\n\nSelect another tab or tap the mask to dismiss."

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

    let scale = container.window?.windowScene?.screen.scale ?? container.traitCollection.displayScale
    let lineHeight = 1 / max(scale, 1)
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

  // MARK: - Configuration

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
    appendLog("content source → \(contentMode == .closure ? "closure" : "dataSource")")
  }

  @objc private func onConfigChanged() {
    applyPresentationConfiguration()
  }

  @objc private func onPassthroughTapped() {
    appendLog("passthrough button tapped (mask did not intercept)")
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
    tip.text = "Notes: The panel is anchored to the currently selected item. On first load, the first item is selected and the panel is shown."

    stack.addArrangedSubview(tip)
    stack.addArrangedSubview(modeSegment)
    stack.addArrangedSubview(makeToggleRow(title: "Tap mask to dismiss", switchView: maskDismissSwitch))
    stack.addArrangedSubview(makeToggleRow(title: "Panel shadow", switchView: shadowSwitch))
    stack.addArrangedSubview(makeToggleRow(title: "Allow flipping above anchor", switchView: allowFlipSwitch))
    stack.addArrangedSubview(makeToggleRow(title: "Fixed panel height (slider)", switchView: preferredHeightSwitch))
    stack.addArrangedSubview(makeSliderRow(title: "Height", slider: heightSlider))
    stack.addArrangedSubview(passthroughButton)

    let dismissBtn = makeFilledButton(title: "Dismiss panel (code)", action: #selector(onDismissPanel))
    stack.addArrangedSubview(dismissBtn)

    let reloadBtn = makeFilledButton(title: "Reload bar items", action: #selector(onReloadBar))
    stack.addArrangedSubview(reloadBtn)

    stack.addArrangedSubview(logTextView)
    // Keep the log area at a fixed height to avoid UI growth from long text.
    logTextView.heightAnchor.constraint(equalToConstant: 160).isActive = true
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
    appendLog("dismissPresentation(animated:) called")
  }

  @objc private func onReloadBar() {
    reloadBarItems()
    appendLog("reloadBarItems (Alpha selected by default)")
  }

  private func appendLog(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    let entry = "\n[\(stamp)] \(line)"
    logTextView.textStorage.append(NSAttributedString(string: entry))

    // Trim old content to avoid performance degradation from unbounded growth.
    if logTextView.textStorage.length > maxLogCharacters {
      let excess = logTextView.textStorage.length - maxLogCharacters
      logTextView.textStorage.deleteCharacters(in: NSRange(location: 0, length: excess))
    }

    // Keep the scroll position near the bottom.
    let bottom = max(logTextView.textStorage.length - 1, 0)
    logTextView.scrollRangeToVisible(NSRange(location: bottom, length: 1))
  }

  private static let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
  }()
}

// MARK: - FKBarPresentationDelegate

extension FKBarPresentationExampleViewController: FKBarPresentationDelegate {
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

// MARK: - FKBarDelegate (forwarding demo)

extension FKBarPresentationExampleViewController: FKBarDelegate {
  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int) {
    appendLog("bar.didSelect index=\(index)")
  }

  func bar(_ bar: FKBar, didDeselect sender: UIView, for item: FKBar.Item, at index: Int) {
    appendLog("bar.didDeselect index=\(index)")
  }
}

// MARK: - FKBarPresentationDataSource

extension FKBarPresentationExampleViewController: FKBarPresentationDataSource {
  func barPresentation(_ barPresentation: FKBarPresentation, presentationViewForItemAt index: Int) -> UIView? {
    guard contentMode == .dataSource else { return nil }
    guard let item = barPresentation.bar.loadedItems[safe: index] else { return nil }
    return makePanelContent(for: index, item: item)
  }
}
