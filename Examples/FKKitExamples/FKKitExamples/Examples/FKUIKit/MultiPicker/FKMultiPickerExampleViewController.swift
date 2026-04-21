//
// FKMultiPickerExampleViewController.swift
//
// Complete copy-ready demo for FKMultiPicker scenarios.
//

import UIKit
import FKUIKit

// MARK: - Global configuration

/// Shared setup helpers for FKMultiPicker demo screens.
enum FKMultiPickerDemoSupport {
  private static var didConfigureGlobalStyle = false

  /// Configures a global picker style once.
  static func configureGlobalStyleIfNeeded() {
    guard !didConfigureGlobalStyle else { return }
    didConfigureGlobalStyle = true

    var config = FKMultiPickerConfiguration()
    config.componentCount = 4
    config.presentationStyle = .halfScreen
    config.toolbarStyle.title = "Global Picker"
    config.toolbarStyle.confirmTitleColor = .systemBlue
    config.toolbarStyle.cancelTitleColor = .secondaryLabel
    config.rowStyle.textColor = .label
    config.rowStyle.selectedTextColor = .systemBlue
    config.rowStyle.rowHeight = 40
    config.containerStyle.cornerRadius = 18
    config.containerStyle.maskColor = UIColor.black.withAlphaComponent(0.38)
    FKMultiPickerManager.shared.defaultConfiguration = config
  }

  /// Sample 3-level custom linkage data.
  static let customThreeLevelNodes: [FKMultiPickerNode] = [
    FKMultiPickerNode(
      id: "electronics",
      title: "Electronics",
      children: [
        FKMultiPickerNode(
          id: "phone",
          title: "Phone",
          children: [
            FKMultiPickerNode(id: "ios", title: "iOS"),
            FKMultiPickerNode(id: "android", title: "Android"),
          ]
        ),
        FKMultiPickerNode(
          id: "laptop",
          title: "Laptop",
          children: [
            FKMultiPickerNode(id: "ultrabook", title: "Ultrabook"),
            FKMultiPickerNode(id: "gaming", title: "Gaming"),
          ]
        ),
      ]
    ),
    FKMultiPickerNode(
      id: "fashion",
      title: "Fashion",
      children: [
        FKMultiPickerNode(
          id: "men",
          title: "Men",
          children: [
            FKMultiPickerNode(id: "tops", title: "Tops"),
            FKMultiPickerNode(id: "pants", title: "Pants"),
          ]
        ),
        FKMultiPickerNode(
          id: "women",
          title: "Women",
          children: [
            FKMultiPickerNode(id: "dress", title: "Dress"),
            FKMultiPickerNode(id: "shoes", title: "Shoes"),
          ]
        ),
      ]
    ),
  ]

  /// Sample single-level data.
  static let singleLevelNodes: [FKMultiPickerNode] = [
    FKMultiPickerNode(id: "cash", title: "Cash"),
    FKMultiPickerNode(id: "card", title: "Credit Card"),
    FKMultiPickerNode(id: "bank", title: "Bank Transfer"),
    FKMultiPickerNode(id: "wallet", title: "E-Wallet"),
  ]
}

// MARK: - View controller

/// A single screen that covers all FKMultiPicker core scenarios.
///
/// This file is intentionally self-contained so it can be copied into other projects.
final class FKMultiPickerExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let callbackLogLabel = UILabel()

  /// Keeps a strong reference for manual dismiss and dynamic updates.
  private var activePicker: FKMultiPicker?
  /// Stores mutable data for dynamic refresh scenario.
  private var dynamicNodes: [FKMultiPickerNode] = FKMultiPickerDemoSupport.customThreeLevelNodes
  private var dynamicVersion = 1
  private let customProvider = FKMultiPickerCustomDataProvider()

  override func viewDidLoad() {
    super.viewDidLoad()
    FKMultiPickerDemoSupport.configureGlobalStyleIfNeeded()
    title = "FKMultiPicker"
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    buildExamples()
  }
}

private extension FKMultiPickerExampleViewController {
  func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    view.addSubview(scrollView)

    contentStack.axis = .vertical
    contentStack.spacing = 16
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    callbackLogLabel.font = .preferredFont(forTextStyle: .footnote)
    callbackLogLabel.textColor = .secondaryLabel
    callbackLogLabel.numberOfLines = 0
    callbackLogLabel.text = "Picker callback logs appear here."

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  func buildExamples() {
    contentStack.addArrangedSubview(makeSectionTitle("Live Callback Log"))
    contentStack.addArrangedSubview(callbackLogLabel)

    addBasicScenesSection()
    addStyleSection()
    addDefaultSelectionSection()
    addCallbacksSection()
    addGlobalAndRefreshSection()
    addDismissSection()
  }

  // MARK: - Feature sections

  func addBasicScenesSection() {
    let section = makeSectionContainer(
      title: "Basic Picker Scenarios",
      subtitle: "Includes 3-level custom, built-in region 4-level, single-level, and one-line popup API."
    )

    section.addArrangedSubview(
      makeActionButton(title: "Show 3-level linkage picker (custom data)") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 3)
        config.toolbarStyle.title = "Select Product Category"
        let picker = FKMultiPicker.present(in: self.view, nodes: FKMultiPickerDemoSupport.customThreeLevelNodes, configuration: config) { [weak self] result in
          self?.appendLog("3-level confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "3-level-custom")
        self.activePicker = picker
      }
    )

    section.addArrangedSubview(
      makeActionButton(title: "Show province-city-district-street 4-level built-in picker") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 4)
        config.toolbarStyle.title = "Select Region"
        let picker = FKMultiPicker.presentRegionPicker(in: self.view, configuration: config) { [weak self] result in
          self?.appendLog("Region confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "4-level-region")
        self.activePicker = picker
      }
    )

    section.addArrangedSubview(
      makeActionButton(title: "Show single-level picker") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 1)
        config.toolbarStyle.title = "Payment Method"
        let picker = FKMultiPicker.present(in: self.view, nodes: FKMultiPickerDemoSupport.singleLevelNodes, configuration: config) { [weak self] result in
          self?.appendLog("Single-level confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "single-level")
        self.activePicker = picker
      }
    )

    section.addArrangedSubview(
      makeActionButton(title: "Show custom data linkage picker (provider protocol)") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 3)
        config.toolbarStyle.title = "Provider Linkage Picker"
        let picker = FKMultiPicker.present(in: self.view, provider: self.customProvider, configuration: config) { [weak self] result in
          self?.appendLog("Provider confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "provider-linkage")
        self.activePicker = picker
      }
    )

    // One-line usage shortcut.
    section.addArrangedSubview(
      makeActionButton(title: "One-line show picker API demo") { [weak self] in
        guard let self else { return }
        self.activePicker = FKMultiPicker.presentRegionPicker(in: self.view) { [weak self] result in
          self?.appendLog("One-line confirmed -> \(result.joinedTitle)")
        }
      }
    )

    contentStack.addArrangedSubview(section)
  }

  func addStyleSection() {
    let section = makeSectionContainer(
      title: "Custom UI and Popup Style",
      subtitle: "Customize text color, fonts, row height, background, popup presentation style, and corner radius."
    )

    section.addArrangedSubview(
      makeActionButton(title: "Custom picker UI (text/font/row/background)") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 3)
        config.toolbarStyle.title = "Custom UI Picker"
        config.toolbarStyle.titleColor = .white
        config.toolbarStyle.confirmTitleColor = .systemYellow
        config.toolbarStyle.cancelTitleColor = .white.withAlphaComponent(0.85)
        config.rowStyle.textColor = .white.withAlphaComponent(0.8)
        config.rowStyle.selectedTextColor = .systemYellow
        config.rowStyle.font = .systemFont(ofSize: 15, weight: .regular)
        config.rowStyle.selectedFont = .systemFont(ofSize: 17, weight: .bold)
        config.rowStyle.rowHeight = 46
        config.containerStyle.backgroundColor = .black
        config.containerStyle.maskColor = UIColor.black.withAlphaComponent(0.55)
        config.containerStyle.cornerRadius = 22

        let picker = FKMultiPicker.present(in: self.view, nodes: FKMultiPickerDemoSupport.customThreeLevelNodes, configuration: config) { [weak self] result in
          self?.appendLog("Custom UI confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "custom-ui")
        self.activePicker = picker
      }
    )

    section.addArrangedSubview(
      makeActionButton(title: "Custom popup style (fullscreen / half / corner radius)") { [weak self] in
        guard let self else { return }
        let useFullScreen = Bool.random()
        var config = FKMultiPickerConfiguration(componentCount: 4)
        config.presentationStyle = useFullScreen ? .fullScreen : .halfScreen
        config.toolbarStyle.title = useFullScreen ? "Fullscreen Picker" : "Half Screen Picker"
        config.containerStyle.cornerRadius = useFullScreen ? 0 : 20
        config.animationDuration = 0.35

        let picker = FKMultiPicker.presentRegionPicker(in: self.view, configuration: config) { [weak self] result in
          self?.appendLog("Popup style confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "popup-style")
        self.activePicker = picker
      }
    )

    contentStack.addArrangedSubview(section)
  }

  func addDefaultSelectionSection() {
    let section = makeSectionContainer(
      title: "Default Selected Items",
      subtitle: "Initialize picker with default selected keys matched by node id or title."
    )

    section.addArrangedSubview(
      makeActionButton(title: "Set default selected items when initialize") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 4)
        config.toolbarStyle.title = "Default Selection"
        config.defaultSelectionKeys = ["440000", "440300", "440305", "440305002"]
        let picker = FKMultiPicker.presentRegionPicker(in: self.view, configuration: config) { [weak self] result in
          self?.appendLog("Default selection confirmed -> \(result.joinedTitle)")
        }
        self.installCommonCallbacks(on: picker, name: "default-selection")
        self.activePicker = picker
      }
    )

    contentStack.addArrangedSubview(section)
  }

  func addCallbacksSection() {
    let section = makeSectionContainer(
      title: "Callbacks",
      subtitle: "Confirm, cancel, and real-time selection change callbacks."
    )

    section.addArrangedSubview(
      makeActionButton(title: "Confirm callback + cancel callback + change callback") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 3)
        config.toolbarStyle.title = "Observe Callbacks"
        let picker = FKMultiPicker.present(in: self.view, nodes: FKMultiPickerDemoSupport.customThreeLevelNodes, configuration: config) { [weak self] result in
          self?.appendLog("Confirm callback -> \(result.joinedTitle)")
        }
        picker.onCancelled = { [weak self] in
          self?.appendLog("Cancel callback -> picker cancelled")
        }
        picker.onSelectionChanged = { [weak self] result in
          self?.appendLog("Realtime change callback -> \(result.joinedTitle)")
        }
        self.activePicker = picker
      }
    )

    contentStack.addArrangedSubview(section)
  }

  func addGlobalAndRefreshSection() {
    let section = makeSectionContainer(
      title: "Global Configuration and Dynamic Refresh",
      subtitle: "Apply global style for all pickers and refresh data dynamically."
    )

    section.addArrangedSubview(
      makeActionButton(title: "Apply global style configuration for all pickers") { [weak self] in
        guard let self else { return }
        FKMultiPickerDemoSupport.configureGlobalStyleIfNeeded()
        self.appendLog("Global style configured. New picker instances use shared defaults.")
      }
    )

    section.addArrangedSubview(
      makeActionButton(title: "Show dynamic refresh picker data") { [weak self] in
        guard let self else { return }
        var config = FKMultiPickerConfiguration(componentCount: 3)
        config.toolbarStyle.title = "Dynamic Data v\(self.dynamicVersion)"

        let picker = FKMultiPicker(configuration: config)
        picker.updateNodes(self.dynamicNodes)
        picker.onSelectionChanged = { [weak self] result in
          self?.appendLog("Dynamic picker changed -> \(result.joinedTitle)")
        }
        picker.onConfirmed = { [weak self] result in
          self?.appendLog("Dynamic picker confirmed -> \(result.joinedTitle)")
        }
        picker.show(in: self.view)
        self.activePicker = picker
      }
    )

    section.addArrangedSubview(
      makeActionButton(title: "Refresh current picker data source now") { [weak self] in
        guard let self else { return }
        self.dynamicVersion += 1
        self.dynamicNodes = self.makeDynamicNodes(version: self.dynamicVersion)
        self.activePicker?.updateNodes(self.dynamicNodes)
        self.activePicker?.reloadData()
        self.appendLog("Dynamic data refreshed to version \(self.dynamicVersion)")
      }
    )

    contentStack.addArrangedSubview(section)
  }

  func addDismissSection() {
    let section = makeSectionContainer(
      title: "Dismiss Control",
      subtitle: "Manually dismiss the currently active picker instance."
    )

    section.addArrangedSubview(
      makeActionButton(title: "Manual dismiss picker") { [weak self] in
        self?.activePicker?.dismiss()
        self?.appendLog("Manual dismiss executed")
      }
    )

    contentStack.addArrangedSubview(section)
  }

  // MARK: - Helpers

  func installCommonCallbacks(on picker: FKMultiPicker, name: String) {
    picker.onSelectionChanged = { [weak self] result in
      self?.appendLog("\(name) changed -> \(result.joinedTitle)")
    }
    picker.onCancelled = { [weak self] in
      self?.appendLog("\(name) cancelled")
    }
  }

  func makeDynamicNodes(version: Int) -> [FKMultiPickerNode] {
    let suffix = "V\(version)"
    return [
      FKMultiPickerNode(
        id: "dynamic-A-\(version)",
        title: "Dynamic A \(suffix)",
        children: [
          FKMultiPickerNode(
            id: "dynamic-A1-\(version)",
            title: "Dynamic A1 \(suffix)",
            children: [
              FKMultiPickerNode(id: "dynamic-A1a-\(version)", title: "Dynamic A1-a \(suffix)"),
              FKMultiPickerNode(id: "dynamic-A1b-\(version)", title: "Dynamic A1-b \(suffix)"),
            ]
          )
        ]
      ),
      FKMultiPickerNode(
        id: "dynamic-B-\(version)",
        title: "Dynamic B \(suffix)",
        children: [
          FKMultiPickerNode(
            id: "dynamic-B1-\(version)",
            title: "Dynamic B1 \(suffix)",
            children: [
              FKMultiPickerNode(id: "dynamic-B1a-\(version)", title: "Dynamic B1-a \(suffix)"),
              FKMultiPickerNode(id: "dynamic-B1b-\(version)", title: "Dynamic B1-b \(suffix)"),
            ]
          )
        ]
      ),
    ]
  }

  func appendLog(_ text: String) {
    callbackLogLabel.text = text
  }

  func makeSectionContainer(title: String, subtitle: String) -> UIStackView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 10
    container.addArrangedSubview(makeSectionTitle(title))
    container.addArrangedSubview(makeSectionSubtitle(subtitle))
    return container
  }

  func makeActionButton(title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    if #available(iOS 15.0, *) {
      var config = UIButton.Configuration.filled()
      config.title = title
      config.baseBackgroundColor = .systemBlue
      config.baseForegroundColor = .white
      config.cornerStyle = .fixed
      config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
      config.titleAlignment = .leading
      button.configuration = config
    } else {
      button.setTitle(title, for: .normal)
      button.contentHorizontalAlignment = .left
      button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
      button.setTitleColor(.white, for: .normal)
      button.backgroundColor = .systemBlue
      button.layer.cornerRadius = 10
      button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
    }
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }

  func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    label.text = text
    return label
  }

  func makeSectionSubtitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}
