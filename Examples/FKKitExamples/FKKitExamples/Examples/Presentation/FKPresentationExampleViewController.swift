//
//  FKPresentationExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

/// Interactive demo for `FKPresentation`: anchor, mask, layout, and embedded UIView / UIViewController content.
final class FKPresentationExampleViewController: UIViewController {
  private let presentation = FKPresentation()

  /// Anchor for `show(from:content:)`: full width under the nav bar, not inside the settings stack.
  private let anchorView: UIView = {
    let v = UIView()
    v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
    v.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Tap here to present"
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .systemBlue

    v.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(lessThanOrEqualTo: v.trailingAnchor, constant: -16),
      label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
    ])

    return v
  }()

  private let passthroughButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.title = "Passthrough (tappable under mask)"
    config.cornerStyle = .medium
    config.baseBackgroundColor = .systemGreen
    config.baseForegroundColor = .white
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    return UIButton(configuration: config)
  }()

  private let logLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.text = "Log:"
    return label
  }()

  private let maskTapToDismissSwitch = UISwitch()
  private let passthroughEnabledSwitch = UISwitch()
  private let preferBelowSwitch = UISwitch()
  private let allowFlipSwitch = UISwitch()
  private let useFixedHeightSwitch = UISwitch()
  private let shadowSwitch = UISwitch()

  private let maskAlphaSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 0.6
    s.value = 0.25
    return s
  }()

  private let cornerRadiusSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 24
    s.value = 12
    return s
  }()

  private let fixedHeightSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 140
    s.maximumValue = 420
    s.value = 260
    return s
  }()

  private var sliderValueLabels: [ObjectIdentifier: UILabel] = [:]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKPresentation"
    view.backgroundColor = .systemBackground
    presentation.delegate = self

    setupUI()
    setupDefaults()
  }

  private func setupUI() {
    // Anchor: pinned to the root view (full width, fixed height ~55pt).
    view.addSubview(anchorView)
    NSLayoutConstraint.activate([
      anchorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      anchorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      anchorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      anchorView.heightAnchor.constraint(equalToConstant: 55)
    ])

    let anchorTap = UITapGestureRecognizer(target: self, action: #selector(onShowUIViewContent))
    anchorView.addGestureRecognizer(anchorTap)

    let container = UIStackView()
    container.axis = .vertical
    container.alignment = .fill
    container.spacing = 12
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: anchorView.bottomAnchor, constant: 16),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      container.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16)
    ])

    passthroughButton.addTarget(self, action: #selector(onPassthroughTapped), for: .touchUpInside)

    let showVCButton = makeButton("Show UIViewController content", action: #selector(onShowUIViewControllerContent))
    let showNoAnimButton = makeButton("Show without animation", action: #selector(onShowNoAnimation))
    showNoAnimButton.backgroundColor = .systemGray5

    container.addArrangedSubview(passthroughButton)
    container.addArrangedSubview(showVCButton)
    container.addArrangedSubview(showNoAnimButton)

    container.addArrangedSubview(makeDivider())

    container.addArrangedSubview(makeToggleRow(title: "Mask tap dismisses", switchView: maskTapToDismissSwitch))
    container.addArrangedSubview(makeToggleRow(title: "Mask passthrough", switchView: passthroughEnabledSwitch))
    container.addArrangedSubview(makeToggleRow(title: "Prefer below anchor", switchView: preferBelowSwitch))
    container.addArrangedSubview(makeToggleRow(title: "Allow flip above", switchView: allowFlipSwitch))
    container.addArrangedSubview(makeToggleRow(title: "Fixed height (layout before animate)", switchView: useFixedHeightSwitch))
    container.addArrangedSubview(makeToggleRow(title: "Show shadow", switchView: shadowSwitch))

    container.addArrangedSubview(makeSliderRow(title: "mask alpha", slider: maskAlphaSlider))
    container.addArrangedSubview(makeSliderRow(title: "corner radius", slider: cornerRadiusSlider))
    container.addArrangedSubview(makeSliderRow(title: "fixed height", slider: fixedHeightSlider))

    container.addArrangedSubview(makeDivider())
    container.addArrangedSubview(logLabel)
  }

  private func setupDefaults() {
    maskTapToDismissSwitch.isOn = true
    passthroughEnabledSwitch.isOn = false
    preferBelowSwitch.isOn = true
    allowFlipSwitch.isOn = false
    useFixedHeightSwitch.isOn = true
    shadowSwitch.isOn = true

    maskAlphaSlider.value = 0.25
    cornerRadiusSlider.value = 12
    fixedHeightSlider.value = 260
  }

  private func makeButton(_ title: String, action: Selector) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.baseBackgroundColor = .systemBlue.withAlphaComponent(0.12)
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
    let b = UIButton(configuration: config)
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }

  private func makeDivider() -> UIView {
    let v = UIView()
    v.backgroundColor = .separator
    v.translatesAutoresizingMaskIntoConstraints = false
    let scale = max(v.window?.windowScene?.screen.scale ?? v.traitCollection.displayScale, 1)
    v.heightAnchor.constraint(equalToConstant: 1 / scale).isActive = true
    return v
  }

  private func makeToggleRow(title: String, switchView: UISwitch) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .fill
    row.spacing = 12

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    switchView.addTarget(self, action: #selector(onToggleChanged), for: .valueChanged)
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
    label.text = "\(title): \(String(format: "%.2f", slider.value))"
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel

    slider.addTarget(self, action: #selector(onSliderChanged(_:)), for: .valueChanged)

    row.addArrangedSubview(label)
    row.addArrangedSubview(slider)

    slider.accessibilityIdentifier = title
    sliderValueLabels[ObjectIdentifier(slider)] = label
    return row
  }

  @objc private func onToggleChanged() {
    // No-op: values read on show.
  }

  @objc private func onSliderChanged(_ sender: UISlider) {
    let key = ObjectIdentifier(sender)
    guard let label = sliderValueLabels[key] else { return }
    let title = sender.accessibilityIdentifier ?? "value"
    label.text = "\(title): \(String(format: "%.2f", sender.value))"
  }

  private func currentConfiguration(animated: Bool) -> FKPresentation.Configuration {
    var cfg = FKPresentation.Configuration.default
    cfg.appearance.backgroundColor = .systemBackground
    cfg.appearance.shadow = shadowSwitch.isOn
      ? .init(color: .black, opacity: 0.18, offset: CGSize(width: 0, height: 2), radius: 6)
      : nil
    cfg.appearance.cornerRadius = CGFloat(cornerRadiusSlider.value)
    cfg.appearance.alpha = 1.0
    cfg.appearance.borderWidth = 0

    cfg.mask.enabled = true
    cfg.mask.backgroundColor = .black
    cfg.mask.alpha = CGFloat(maskAlphaSlider.value)
    cfg.mask.tapToDismissEnabled = maskTapToDismissSwitch.isOn
    cfg.mask.passthroughViews = passthroughEnabledSwitch.isOn ? [passthroughButton] : []

    cfg.layout.preferBelowSource = preferBelowSwitch.isOn
    cfg.layout.allowFlipToAbove = allowFlipSwitch.isOn
    cfg.layout.verticalSpacing = 0
    cfg.layout.clampToSafeArea = false
    cfg.layout.widthMode = .fullWidth

    cfg.content.containerInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
    cfg.content.fallbackBackgroundColor = .systemBackground

    cfg.content.preferredHeight = useFixedHeightSwitch.isOn ? CGFloat(fixedHeightSlider.value) : nil
    cfg.content.maxHeight = nil

    // Animations: keep durations modest for debugging.
    cfg.animation.show.duration = animated ? 0.28 : 0
    cfg.animation.dismiss.duration = animated ? 0.18 : 0

    cfg.interaction.isUserInteractionEnabledDuringAnimation = true
    cfg.interaction.allowDismissingDuringReposition = true

    return cfg
  }

  @objc private func onShowUIViewContent() {
    presentation.configuration = currentConfiguration(animated: true)

    let content = ExamplePresentationContentView()
    log("show UIView content")
    presentation.show(from: anchorView, content: content, animated: true)
  }

  @objc private func onShowUIViewControllerContent() {
    presentation.configuration = currentConfiguration(animated: true)
    let content = ExamplePresentationContentViewController()
    content.preferredContentSize = CGSize(width: 1, height: CGFloat(fixedHeightSlider.value))
    log("show UIViewController content")
    presentation.show(from: anchorView, content: content, animated: true)
  }

  @objc private func onShowNoAnimation() {
    presentation.configuration = currentConfiguration(animated: false)
    let content = ExamplePresentationContentView()
    log("show no animation")
    presentation.show(from: anchorView, content: content, animated: false)
  }

  @objc private func onPassthroughTapped() {
    log("Passthrough button tapped")
  }

  private func log(_ message: String) {
    logLabel.text = "Log:\n" + message
  }

}

private final class ExamplePresentationContentView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.text = "Presentation content (UIView)"
    title.font = .preferredFont(forTextStyle: .headline)
    title.numberOfLines = 0

    let items = ["Smart sort", "Nearest", "Top rated", "Lowest price", "Highest price", "More…"]
    let list = UIStackView()
    list.axis = .vertical
    list.spacing = 6

    for t in items {
      let label = UILabel()
      label.text = "• " + t
      label.font = .preferredFont(forTextStyle: .body)
      label.textColor = .label
      list.addArrangedSubview(label)
    }

    let hint = UILabel()
    hint.text = "Tap the mask to dismiss. With passthrough on, the green button does not dismiss."
    hint.numberOfLines = 0
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(list)
    stack.addArrangedSubview(hint)
    stack.setContentCompressionResistancePriority(.required, for: .vertical)

    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class ExamplePresentationContentViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.text = "Presentation content (UIViewController)"
    title.font = .preferredFont(forTextStyle: .headline)

    let list = UIStackView()
    list.axis = .vertical
    list.spacing = 6

    for i in 1...8 {
      let label = UILabel()
      label.text = "• VC Item \(i)"
      label.font = .preferredFont(forTextStyle: .body)
      list.addArrangedSubview(label)
    }

    let hint = UILabel()
    hint.text = "When Reduce Motion is on, animations avoid transform-based motion (alpha only)."
    hint.numberOfLines = 0
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(list)
    stack.addArrangedSubview(hint)

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.topAnchor),
      stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
  }
}

extension FKPresentationExampleViewController: FKPresentationDelegate {
  func presentationWillPresent(_ presentation: FKPresentation) {
    log("presentationWillPresent")
  }

  func presentationDidPresent(_ presentation: FKPresentation) {
    log("presentationDidPresent")
  }

  func presentationShouldDismiss(_ presentation: FKPresentation) -> Bool {
    log("presentationShouldDismiss? -> true")
    return true
  }

  func presentationWillDismiss(_ presentation: FKPresentation) {
    log("presentationWillDismiss")
  }

  func presentationDidDismiss(_ presentation: FKPresentation) {
    log("presentationDidDismiss")
  }

  func presentation(_ presentation: FKPresentation, willRepositionTo rect: inout CGRect, in view: inout UIView) {
    // Keep default anchor behavior for demo. This hook is here for debugging extensibility.
    _ = rect
    _ = view
  }
}
