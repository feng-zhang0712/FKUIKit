//
// FKMultiPicker.swift
//

import UIKit

/// Multi-column `UIPickerView` in a bottom sheet, with linked data between columns.
@MainActor
public final class FKMultiPicker: UIView {
  /// Default configuration for new instances and `present` helpers when no configuration is passed.
  public static var defaultConfiguration = FKMultiPickerConfiguration()

  public private(set) var configuration: FKMultiPickerConfiguration
  public weak var dataSource: FKMultiPickerDataSource?
  public weak var delegate: FKMultiPickerDelegate?

  public var onSelectionChanged: ((FKMultiPickerSelectionResult) -> Void)?
  public var onConfirmed: ((FKMultiPickerSelectionResult) -> Void)?
  public var onCancelled: (() -> Void)?

  private let overlayView = UIControl()
  private let containerView = UIView()
  private let toolbarView = UIView()
  private let titleLabel = UILabel()
  private let cancelButton = UIButton(type: .system)
  private let confirmButton = UIButton(type: .system)
  private let separatorView = UIView()
  private let pickerView = UIPickerView()

  private var containerHeightConstraint: NSLayoutConstraint?
  private var dataByLevel: [[FKMultiPickerNode]] = []
  private var selectedIndexByLevel: [Int] = []
  private weak var hostView: UIView?
  private var providerBridge: FKMultiPickerDataProviderBridge?

  public init(configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration) {
    self.configuration = configuration
    super.init(frame: .zero)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    configuration = FKMultiPicker.defaultConfiguration
    super.init(coder: coder)
    setupUI()
  }

  public func configure(_ configuration: FKMultiPickerConfiguration) {
    self.configuration = configuration
    applyAppearance()
    updateContainerHeight()
    pickerView.reloadAllComponents()
    applyDefaultSelection(animated: false)
  }

  public func show(in hostView: UIView? = nil) {
    guard superview == nil else { return }
    let targetView = hostView ?? Self.defaultHostView()
    guard let targetView else { return }
    self.hostView = targetView
    frame = targetView.bounds
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    targetView.addSubview(self)
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalTo: targetView.widthAnchor),
      heightAnchor.constraint(equalTo: targetView.heightAnchor),
      centerXAnchor.constraint(equalTo: targetView.centerXAnchor),
      centerYAnchor.constraint(equalTo: targetView.centerYAnchor),
    ])
    layoutIfNeeded()
    reloadData()
    updateContainerHeight()
    layoutIfNeeded()
    containerView.accessibilityViewIsModal = true
    FKMultiPickerAnimator.present(
      maskView: overlayView,
      containerView: containerView,
      duration: configuration.animationDuration
    )
  }

  public func dismiss(completion: (() -> Void)? = nil) {
    guard superview != nil else {
      completion?()
      return
    }
    endEditing(true)
    FKMultiPickerAnimator.dismiss(
      maskView: overlayView,
      containerView: containerView,
      duration: configuration.animationDuration
    ) { [weak self] in
      self?.containerView.accessibilityViewIsModal = false
      self?.removeFromSuperview()
      completion?()
    }
  }

  public func reloadData() {
    let roots: [FKMultiPickerNode]
    if let dataSource {
      roots = dataSource.rootNodes(for: self)
    } else if let existing = dataByLevel.first, !existing.isEmpty {
      roots = existing
    } else {
      roots = []
    }
    dataByLevel = [roots]
    selectedIndexByLevel = [0]
    rebuildCascade(from: 0)
    pickerView.reloadAllComponents()
    applyDefaultSelection(animated: false)
    notifySelectionChanged()
  }

  public func resetSelection(animated: Bool = true) {
    selectedIndexByLevel = Array(repeating: 0, count: max(1, dataByLevel.count))
    rebuildCascade(from: 0)
    pickerView.reloadAllComponents()
    applySelectionToPicker(animated: animated)
    notifySelectionChanged()
  }

  public func restoreSelection(from result: FKMultiPickerSelectionResult, animated: Bool = false) {
    guard !result.items.isEmpty else { return }
    guard !dataByLevel.isEmpty, !dataByLevel[0].isEmpty else { return }
    let sorted = result.items.sorted { $0.level < $1.level }
    for item in sorted {
      guard item.level < dataByLevel.count else { break }
      let nodes = dataByLevel[item.level]
      if nodes.isEmpty { break }
      guard let row = nodes.firstIndex(where: { $0.id == item.node.id || $0.title == item.node.title }) else {
        break
      }
      while selectedIndexByLevel.count <= item.level {
        selectedIndexByLevel.append(0)
      }
      selectedIndexByLevel[item.level] = row
      rebuildCascade(from: item.level)
    }
    pickerView.reloadAllComponents()
    applySelectionToPicker(animated: animated)
    notifySelectionChanged()
  }

  /// Replaces level-0 data and clears the selection (embedded `children` drive deeper levels unless a `dataSource` supplies children).
  public func updateNodes(_ nodes: [FKMultiPickerNode]) {
    dataByLevel = [nodes]
    selectedIndexByLevel = [0]
    rebuildCascade(from: 0)
    pickerView.reloadAllComponents()
    applyDefaultSelection(animated: false)
    notifySelectionChanged()
  }

  /// Attaches a `FKMultiPickerDataProviding` instance and reloads from it (replaces `dataSource` with an internal bridge).
  public func setDataProvider(_ provider: FKMultiPickerDataProviding) {
    let bridge = FKMultiPickerDataProviderBridge(provider: provider)
    providerBridge = bridge
    dataSource = bridge
    reloadData()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    if case .fullScreen = configuration.presentationStyle {
      updateContainerHeight()
    }
  }
}

private extension FKMultiPicker {
  func setupUI() {
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear

    overlayView.translatesAutoresizingMaskIntoConstraints = false
    overlayView.addTarget(self, action: #selector(maskTapped), for: .touchUpInside)
    addSubview(overlayView)

    containerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(containerView)

    toolbarView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(toolbarView)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.textAlignment = .center
    toolbarView.addSubview(titleLabel)

    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    toolbarView.addSubview(cancelButton)

    confirmButton.translatesAutoresizingMaskIntoConstraints = false
    confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    toolbarView.addSubview(confirmButton)

    separatorView.translatesAutoresizingMaskIntoConstraints = false
    toolbarView.addSubview(separatorView)

    pickerView.translatesAutoresizingMaskIntoConstraints = false
    pickerView.dataSource = self
    pickerView.delegate = self
    containerView.addSubview(pickerView)

    NSLayoutConstraint.activate([
      overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
      overlayView.topAnchor.constraint(equalTo: topAnchor),
      overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),

      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      toolbarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      toolbarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      toolbarView.topAnchor.constraint(equalTo: containerView.topAnchor),
      toolbarView.heightAnchor.constraint(equalToConstant: configuration.toolbarHeight),

      cancelButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
      cancelButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
      cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),

      confirmButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
      confirmButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
      confirmButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),

      titleLabel.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
      titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cancelButton.trailingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: confirmButton.leadingAnchor, constant: -8),
      titleLabel.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

      separatorView.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
      separatorView.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor),
      separatorView.bottomAnchor.constraint(equalTo: toolbarView.bottomAnchor),
      separatorView.heightAnchor.constraint(equalToConstant: 0.5),

      pickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      pickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      pickerView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
      pickerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
    ])

    containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 300)
    containerHeightConstraint?.isActive = true
    applyAppearance()
  }

  func applyAppearance() {
    let toolbarStyle = configuration.toolbarStyle
    let rowStyle = configuration.rowStyle
    let containerStyle = configuration.containerStyle

    overlayView.backgroundColor = containerStyle.maskColor
    containerView.backgroundColor = containerStyle.backgroundColor
    containerView.layer.cornerRadius = containerStyle.cornerRadius
    containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    containerView.layer.shadowColor = containerStyle.shadowColor.cgColor
    containerView.layer.shadowOpacity = containerStyle.shadowOpacity
    containerView.layer.shadowRadius = containerStyle.shadowRadius
    containerView.layer.shadowOffset = containerStyle.shadowOffset

    toolbarView.backgroundColor = containerStyle.backgroundColor
    titleLabel.text = toolbarStyle.title
    titleLabel.textColor = toolbarStyle.titleColor
    titleLabel.font = toolbarStyle.titleFont

    cancelButton.setTitle(toolbarStyle.cancelTitle, for: .normal)
    cancelButton.setTitleColor(toolbarStyle.cancelTitleColor, for: .normal)
    cancelButton.titleLabel?.font = toolbarStyle.cancelTitleFont

    confirmButton.setTitle(toolbarStyle.confirmTitle, for: .normal)
    confirmButton.setTitleColor(toolbarStyle.confirmTitleColor, for: .normal)
    confirmButton.titleLabel?.font = toolbarStyle.confirmTitleFont

    separatorView.isHidden = !toolbarStyle.showsSeparator
    separatorView.backgroundColor = toolbarStyle.separatorColor
    pickerView.subviews.forEach { view in
      if view.frame.height <= 1 {
        view.isHidden = !toolbarStyle.showsSeparator
      }
    }

    if configuration.dismissOnMaskTap {
      overlayView.isAccessibilityElement = true
      overlayView.accessibilityTraits = .button
      overlayView.accessibilityLabel = "Dismiss picker"
    } else {
      overlayView.isAccessibilityElement = false
      overlayView.accessibilityLabel = nil
    }

    pickerView.rowSize(forComponent: 0)
    _ = rowStyle
  }

  func updateContainerHeight() {
    let fullHeight = configuration.toolbarHeight + configuration.pickerHeight
    switch configuration.presentationStyle {
    case .halfScreen:
      containerHeightConstraint?.constant = fullHeight
    case .fullScreen:
      let maxHeight = bounds.height > 0 ? bounds.height : UIScreen.main.bounds.height
      containerHeightConstraint?.constant = maxHeight
    case .custom(let height):
      containerHeightConstraint?.constant = max(configuration.toolbarHeight + 120, height)
    }
    layoutIfNeeded()
  }

  func rebuildCascade(from level: Int) {
    guard !dataByLevel.isEmpty else { return }
    if level == 0 {
      normalizeSelectionIndex(for: 0)
    }

    let targetComponents = max(1, configuration.numberOfColumns)
    if dataByLevel.count > targetComponents {
      dataByLevel = Array(dataByLevel.prefix(targetComponents))
      selectedIndexByLevel = Array(selectedIndexByLevel.prefix(targetComponents))
    }

    var currentLevel = level
    while currentLevel < targetComponents - 1 {
      guard currentLevel < dataByLevel.count else { break }
      guard let selectedNode = selectedNode(at: currentLevel) else {
        trimFromLevel(currentLevel + 1)
        break
      }
      let children = dataSource?.multiPicker(self, childrenOf: selectedNode, atLevel: currentLevel) ?? selectedNode.children
      if children.isEmpty {
        trimFromLevel(currentLevel + 1)
        break
      }

      if currentLevel + 1 < dataByLevel.count {
        dataByLevel[currentLevel + 1] = children
      } else {
        dataByLevel.append(children)
      }

      if currentLevel + 1 < selectedIndexByLevel.count {
        selectedIndexByLevel[currentLevel + 1] = min(selectedIndexByLevel[currentLevel + 1], max(0, children.count - 1))
      } else {
        selectedIndexByLevel.append(0)
      }
      currentLevel += 1
    }
  }

  func trimFromLevel(_ level: Int) {
    guard level < dataByLevel.count else { return }
    dataByLevel = Array(dataByLevel.prefix(level))
    selectedIndexByLevel = Array(selectedIndexByLevel.prefix(level))
    if dataByLevel.isEmpty {
      dataByLevel = [[]]
      selectedIndexByLevel = [0]
    }
  }

  func normalizeSelectionIndex(for level: Int) {
    guard level < dataByLevel.count else { return }
    guard !dataByLevel[level].isEmpty else {
      selectedIndexByLevel[level] = 0
      return
    }
    selectedIndexByLevel[level] = min(selectedIndexByLevel[level], dataByLevel[level].count - 1)
  }

  func selectedNode(at level: Int) -> FKMultiPickerNode? {
    guard level < dataByLevel.count else { return nil }
    let nodes = dataByLevel[level]
    guard !nodes.isEmpty else { return nil }
    let row = max(0, min(selectedIndexByLevel[level], nodes.count - 1))
    return nodes[row]
  }

  func currentSelectionResult() -> FKMultiPickerSelectionResult {
    let items = dataByLevel.enumerated().compactMap { level, nodes -> FKMultiPickerSelectionItem? in
      guard !nodes.isEmpty, level < selectedIndexByLevel.count else { return nil }
      let row = max(0, min(selectedIndexByLevel[level], nodes.count - 1))
      return FKMultiPickerSelectionItem(level: level, row: row, node: nodes[row])
    }
    return FKMultiPickerSelectionResult(items: items)
  }

  func notifySelectionChanged() {
    let result = currentSelectionResult()
    confirmButton.isEnabled = !result.items.isEmpty
    onSelectionChanged?(result)
    delegate?.multiPicker(self, didChange: result)
  }

  func applyDefaultSelection(animated: Bool) {
    guard !configuration.defaultSelectionKeys.isEmpty else {
      applySelectionToPicker(animated: animated)
      return
    }

    for level in 0..<min(configuration.defaultSelectionKeys.count, dataByLevel.count) {
      let key = configuration.defaultSelectionKeys[level]
      let nodes = dataByLevel[level]
      if let row = nodes.firstIndex(where: { $0.id == key || $0.title == key }) {
        selectedIndexByLevel[level] = row
        rebuildCascade(from: level)
      } else {
        selectedIndexByLevel[level] = 0
      }
    }
    pickerView.reloadAllComponents()
    applySelectionToPicker(animated: animated)
  }

  func applySelectionToPicker(animated: Bool) {
    for level in 0..<dataByLevel.count {
      let row = min(selectedIndexByLevel[level], max(0, dataByLevel[level].count - 1))
      if row >= 0, level < pickerView.numberOfComponents {
        pickerView.selectRow(row, inComponent: level, animated: animated)
      }
    }
  }

  @objc
  func maskTapped() {
    guard configuration.dismissOnMaskTap else { return }
    onCancelled?()
    delegate?.multiPickerDidCancel(self)
    dismiss()
  }

  @objc
  func cancelTapped() {
    onCancelled?()
    delegate?.multiPickerDidCancel(self)
    dismiss()
  }

  @objc
  func confirmTapped() {
    let result = currentSelectionResult()
    guard !result.items.isEmpty else { return }
    onConfirmed?(result)
    delegate?.multiPicker(self, didConfirm: result)
    dismiss()
  }

  static func defaultHostView() -> UIView? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: { $0.isKeyWindow })
    } else {
      return UIApplication.shared.keyWindow
    }
  }
}

extension FKMultiPicker: UIPickerViewDataSource, UIPickerViewDelegate {
  public func numberOfComponents(in pickerView: UIPickerView) -> Int {
    min(configuration.numberOfColumns, max(1, dataByLevel.count))
  }

  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    guard component < dataByLevel.count else { return 0 }
    return dataByLevel[component].count
  }

  public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    configuration.rowStyle.rowHeight
  }

  public func pickerView(
    _ pickerView: UIPickerView,
    viewForRow row: Int,
    forComponent component: Int,
    reusing view: UIView?
  ) -> UIView {
    let label = FKMultiPickerRowFactory.makeLabel(reusing: view)
    guard component < dataByLevel.count, row < dataByLevel[component].count else {
      label.text = nil
      return label
    }
    let node = dataByLevel[component][row]
    label.text = node.title
    label.accessibilityLabel = node.title
    let isSelected = selectedIndexByLevel.indices.contains(component) && selectedIndexByLevel[component] == row
    label.textColor = isSelected ? configuration.rowStyle.selectedTextColor : configuration.rowStyle.textColor
    label.font = isSelected ? configuration.rowStyle.selectedFont : configuration.rowStyle.font
    return label
  }

  public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard component < selectedIndexByLevel.count else { return }
    selectedIndexByLevel[component] = row
    rebuildCascade(from: component)
    pickerView.reloadAllComponents()
    applySelectionToPicker(animated: false)
    notifySelectionChanged()
  }
}

public extension FKMultiPicker {
  @discardableResult
  static func present(
    in hostView: UIView? = nil,
    roots: [FKMultiPickerNode],
    configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    let picker = FKMultiPicker(configuration: configuration)
    picker.updateNodes(roots)
    picker.onConfirmed = onConfirmed
    picker.show(in: hostView)
    return picker
  }

  @discardableResult
  static func present(
    in hostView: UIView? = nil,
    dataProvider: FKMultiPickerDataProviding,
    configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    let picker = FKMultiPicker(configuration: configuration)
    picker.setDataProvider(dataProvider)
    picker.onConfirmed = onConfirmed
    picker.show(in: hostView)
    return picker
  }

  @discardableResult
  static func presentSampleAddressPicker(
    in hostView: UIView? = nil,
    configuration: FKMultiPickerConfiguration = FKMultiPicker.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    present(
      in: hostView,
      roots: FKMultiPickerSampleAddressData.tree,
      configuration: configuration,
      onConfirmed: onConfirmed
    )
  }
}
