//
// FKMultiPicker.swift
//
// Native cascading multi-level picker component.
//

import UIKit

/// Native UIKit cascading picker that supports unlimited level data trees.
@MainActor
public final class FKMultiPicker: UIView {
  /// Instance configuration.
  public private(set) var configuration: FKMultiPickerConfiguration
  /// Picker data source.
  public weak var dataSource: FKMultiPickerDataSource?
  /// Picker delegate.
  public weak var delegate: FKMultiPickerDelegate?

  /// Realtime callback for selection changes.
  public var onSelectionChanged: ((FKMultiPickerSelectionResult) -> Void)?
  /// Confirmation callback.
  public var onConfirmed: ((FKMultiPickerSelectionResult) -> Void)?
  /// Cancel callback.
  public var onCancelled: (() -> Void)?

  /// Fullscreen overlay used for dimming and tap-to-dismiss interaction.
  private let overlayView = UIControl()
  /// Bottom sheet container that hosts toolbar and picker view.
  private let containerView = UIView()
  /// Top toolbar section that contains title and actions.
  private let toolbarView = UIView()
  /// Center title label displayed in toolbar.
  private let titleLabel = UILabel()
  /// Cancel action button on the leading side.
  private let cancelButton = UIButton(type: .system)
  /// Confirm action button on the trailing side.
  private let confirmButton = UIButton(type: .system)
  /// Optional separator under toolbar.
  private let separatorView = UIView()
  /// UIKit wheel picker used for multi-column linkage display.
  private let pickerView = UIPickerView()

  /// Reserved bottom constraint placeholder for future layout adjustments.
  private var containerBottomConstraint: NSLayoutConstraint?
  /// Height constraint of the sheet container.
  private var containerHeightConstraint: NSLayoutConstraint?
  /// Data cache per visible level. Each nested array represents one component.
  private var dataByLevel: [[FKMultiPickerNode]] = []
  /// Selected row index per visible level.
  private var selectedIndexByLevel: [Int] = []
  /// Host view where picker is presented.
  private weak var hostView: UIView?
  /// Internal bridge retaining provider-style data source.
  private var providerBridge: FKMultiPickerProviderBridge?

  /// Creates picker with custom configuration.
  public init(configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration) {
    self.configuration = configuration
    super.init(frame: .zero)
    setupUI()
  }

  /// Interface Builder initializer.
  public required init?(coder: NSCoder) {
    configuration = FKMultiPickerManager.shared.defaultConfiguration
    super.init(coder: coder)
    setupUI()
  }

  /// Applies a full configuration and refreshes styles.
  ///
  /// This API updates visual style and layout-related configuration for the current instance.
  ///
  /// - Parameter configuration: New picker configuration.
  public func configure(_ configuration: FKMultiPickerConfiguration) {
    self.configuration = configuration
    applyAppearance()
    updateContainerHeight()
    pickerView.reloadAllComponents()
    applyDefaultSelection(animated: false)
  }

  /// Presents picker in a host view.
  ///
  /// - Parameter hostView: Target container view. When omitted, the key window is used.
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
    FKMultiPickerAnimator.present(
      maskView: overlayView,
      containerView: containerView,
      duration: configuration.animationDuration
    )
  }

  /// Dismisses picker.
  ///
  /// - Parameter completion: Optional callback executed after dismiss animation completes.
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
      self?.removeFromSuperview()
      completion?()
    }
  }

  /// Reloads root and dependent levels from data source.
  ///
  /// This method resets selection state to first rows, rebuilds cascade data, and notifies
  /// realtime selection callback with the reconstructed default result.
  public func reloadData() {
    let roots = dataSource?.rootNodes(for: self) ?? []
    dataByLevel = [roots]
    selectedIndexByLevel = [0]
    rebuildCascade(from: 0)
    pickerView.reloadAllComponents()
    applyDefaultSelection(animated: false)
    notifySelectionChanged()
  }

  /// Resets current selected rows to first valid item.
  ///
  /// - Parameter animated: Whether picker wheel movement is animated.
  public func resetSelection(animated: Bool = true) {
    selectedIndexByLevel = Array(repeating: 0, count: max(1, dataByLevel.count))
    rebuildCascade(from: 0)
    pickerView.reloadAllComponents()
    applySelectionToPicker(animated: animated)
    notifySelectionChanged()
  }

  /// Updates root nodes directly for business scenarios without delegate object.
  ///
  /// - Parameter nodes: Root nodes for level 0.
  public func updateNodes(_ nodes: [FKMultiPickerNode]) {
    dataByLevel = [nodes]
    selectedIndexByLevel = [0]
    rebuildCascade(from: 0)
    pickerView.reloadAllComponents()
    applyDefaultSelection(animated: false)
    notifySelectionChanged()
  }

  /// Binds a standalone provider object to this picker.
  ///
  /// This API keeps provider retained internally and bridges it to `FKMultiPickerDataSource`.
  ///
  /// - Parameter provider: Provider that resolves root and child nodes.
  public func bindDataProvider(_ provider: FKMultiPickerDataProviding) {
    let bridge = FKMultiPickerProviderBridge(provider: provider)
    providerBridge = bridge
    dataSource = bridge
    reloadData()
  }
}

private extension FKMultiPicker {
  /// Builds and constraints all UIKit subviews.
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

    // Overlay always covers the full host area to support dimming and tap dismissal.
    NSLayoutConstraint.activate([
      overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
      overlayView.topAnchor.constraint(equalTo: topAnchor),
      overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),

      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      // The sheet is pinned to the very bottom edge to avoid visual gaps.
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

      // Keep title truly centered in the toolbar while respecting button occupancy.
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
      pickerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 300)
    containerHeightConstraint?.isActive = true
    applyAppearance()
  }

  /// Applies all style values from the current configuration.
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
    // Hide native selection lines when caller disables separator style.
    pickerView.subviews.forEach { view in
      if view.frame.height <= 1 {
        view.isHidden = !toolbarStyle.showsSeparator
      }
    }

    // Touching row metrics forces picker layout update for new row style values.
    pickerView.rowSize(forComponent: 0)
    _ = rowStyle
  }

  /// Recomputes container height based on selected presentation style.
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

  /// Rebuilds all levels after a specific level changed.
  ///
  /// The linkage rule is:
  /// 1. Keep current level selection.
  /// 2. Recompute child list of the selected node.
  /// 3. Replace all deeper levels with refreshed children.
  /// 4. Clamp selected rows to valid ranges.
  ///
  /// - Parameter level: Level where selection has changed.
  func rebuildCascade(from level: Int) {
    guard !dataByLevel.isEmpty else { return }
    if level == 0 {
      normalizeSelectionIndex(for: 0)
    }

    let targetComponents = max(1, configuration.componentCount)
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
      // Resolve next-level data through external source first, fallback to embedded children.
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

  /// Drops all data and selected indices from the given level to the end.
  ///
  /// - Parameter level: First level to remove.
  func trimFromLevel(_ level: Int) {
    guard level < dataByLevel.count else { return }
    dataByLevel = Array(dataByLevel.prefix(level))
    selectedIndexByLevel = Array(selectedIndexByLevel.prefix(level))
    if dataByLevel.isEmpty {
      dataByLevel = [[]]
      selectedIndexByLevel = [0]
    }
  }

  /// Clamps selected row index to safe bounds for a level.
  ///
  /// - Parameter level: Level whose selected index should be normalized.
  func normalizeSelectionIndex(for level: Int) {
    guard level < dataByLevel.count else { return }
    guard !dataByLevel[level].isEmpty else {
      selectedIndexByLevel[level] = 0
      return
    }
    selectedIndexByLevel[level] = min(selectedIndexByLevel[level], dataByLevel[level].count - 1)
  }

  /// Returns currently selected node at a level if available.
  ///
  /// - Parameter level: Component level.
  /// - Returns: Selected node or `nil` when level has no data.
  func selectedNode(at level: Int) -> FKMultiPickerNode? {
    guard level < dataByLevel.count else { return nil }
    let nodes = dataByLevel[level]
    guard !nodes.isEmpty else { return nil }
    let row = max(0, min(selectedIndexByLevel[level], nodes.count - 1))
    return nodes[row]
  }

  /// Builds a snapshot result from current selected rows.
  ///
  /// - Returns: Selection result across all active levels.
  func currentSelectionResult() -> FKMultiPickerSelectionResult {
    let items = dataByLevel.enumerated().compactMap { level, nodes -> FKMultiPickerSelectionItem? in
      guard !nodes.isEmpty, level < selectedIndexByLevel.count else { return nil }
      let row = max(0, min(selectedIndexByLevel[level], nodes.count - 1))
      return FKMultiPickerSelectionItem(level: level, row: row, node: nodes[row])
    }
    return FKMultiPickerSelectionResult(items: items)
  }

  /// Dispatches realtime selection callback to closures and delegate.
  func notifySelectionChanged() {
    let result = currentSelectionResult()
    onSelectionChanged?(result)
    delegate?.multiPicker(self, didChange: result)
  }

  /// Applies default selection keys from configuration.
  ///
  /// Matching strategy:
  /// - Prefer node `id`.
  /// - Fallback to node `title`.
  ///
  /// - Parameter animated: Whether picker wheel movement is animated.
  func applyDefaultSelection(animated: Bool) {
    guard !configuration.defaultSelectionKeys.isEmpty else {
      applySelectionToPicker(animated: animated)
      return
    }

    // Try restoring each level by matching id first, then title fallback.
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

  /// Scrolls each picker component to current selected indices.
  ///
  /// - Parameter animated: Whether picker wheel movement is animated.
  func applySelectionToPicker(animated: Bool) {
    for level in 0..<dataByLevel.count {
      let row = min(selectedIndexByLevel[level], max(0, dataByLevel[level].count - 1))
      if row >= 0, level < pickerView.numberOfComponents {
        pickerView.selectRow(row, inComponent: level, animated: animated)
      }
    }
  }

  @objc
  /// Handles overlay tap dismissal.
  func maskTapped() {
    guard configuration.dismissOnMaskTap else { return }
    onCancelled?()
    delegate?.multiPickerDidCancel(self)
    dismiss()
  }

  @objc
  /// Handles cancel button action.
  func cancelTapped() {
    onCancelled?()
    delegate?.multiPickerDidCancel(self)
    dismiss()
  }

  @objc
  /// Handles confirm button action.
  func confirmTapped() {
    let result = currentSelectionResult()
    onConfirmed?(result)
    delegate?.multiPicker(self, didConfirm: result)
    dismiss()
  }

  /// Resolves a default host view from the current key window.
  ///
  /// - Returns: Best-effort key window for picker presentation.
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

@MainActor
/// Internal adapter that converts provider-based API into data-source callbacks.
private final class FKMultiPickerProviderBridge: FKMultiPickerDataSource {
  /// Wrapped provider retained by picker.
  private let provider: FKMultiPickerDataProviding

  /// Creates a bridge object.
  ///
  /// - Parameter provider: Provider to bridge.
  init(provider: FKMultiPickerDataProviding) {
    self.provider = provider
  }

  /// Returns root nodes from wrapped provider.
  func rootNodes(for picker: FKMultiPicker) -> [FKMultiPickerNode] {
    provider.rootNodes()
  }

  /// Returns child nodes from wrapped provider.
  func multiPicker(
    _ picker: FKMultiPicker,
    childrenOf node: FKMultiPickerNode,
    atLevel level: Int
  ) -> [FKMultiPickerNode] {
    provider.children(of: node, atLevel: level)
  }
}

extension FKMultiPicker: UIPickerViewDataSource, UIPickerViewDelegate {
  /// Returns the number of visible picker components.
  public func numberOfComponents(in pickerView: UIPickerView) -> Int {
    min(configuration.componentCount, max(1, dataByLevel.count))
  }

  /// Returns row count for a component.
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    guard component < dataByLevel.count else { return 0 }
    return dataByLevel[component].count
  }

  /// Returns row height for a component.
  public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    configuration.rowStyle.rowHeight
  }

  public func pickerView(
    _ pickerView: UIPickerView,
    viewForRow row: Int,
    forComponent component: Int,
    reusing view: UIView?
  ) -> UIView {
    // Build or reuse labels to avoid repeated view allocations while scrolling.
    let label = FKMultiPickerRowFactory.makeLabel(reusing: view)
    guard component < dataByLevel.count, row < dataByLevel[component].count else {
      label.text = nil
      return label
    }
    let node = dataByLevel[component][row]
    label.text = node.title
    let isSelected = selectedIndexByLevel.indices.contains(component) && selectedIndexByLevel[component] == row
    label.textColor = isSelected ? configuration.rowStyle.selectedTextColor : configuration.rowStyle.textColor
    label.font = isSelected ? configuration.rowStyle.selectedFont : configuration.rowStyle.font
    return label
  }

  /// Handles user selection and triggers cascade refresh.
  ///
  /// - Parameters:
  ///   - pickerView: Source picker view.
  ///   - row: Newly selected row index.
  ///   - component: Component index where selection changed.
  public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard component < selectedIndexByLevel.count else { return }
    selectedIndexByLevel[component] = row
    // Cascade refresh from the changed level to all deeper levels.
    rebuildCascade(from: component)
    pickerView.reloadAllComponents()
    applySelectionToPicker(animated: false)
    notifySelectionChanged()
  }
}

public extension FKMultiPicker {
  /// One-line helper for showing picker with array tree data.
  ///
  /// - Parameters:
  ///   - hostView: Target container view.
  ///   - nodes: Root nodes at level 0.
  ///   - configuration: Picker configuration.
  ///   - onConfirmed: Confirmation callback.
  /// - Returns: Presented picker instance for further operations.
  @discardableResult
  static func present(
    in hostView: UIView? = nil,
    nodes: [FKMultiPickerNode],
    configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    let picker = FKMultiPicker(configuration: configuration)
    picker.updateNodes(nodes)
    picker.onConfirmed = onConfirmed
    picker.show(in: hostView)
    return picker
  }

  /// One-line helper for showing picker with a provider object.
  ///
  /// - Parameters:
  ///   - hostView: Target container view.
  ///   - provider: Provider responsible for resolving linkage data.
  ///   - configuration: Picker configuration.
  ///   - onConfirmed: Confirmation callback.
  /// - Returns: Presented picker instance for further operations.
  @discardableResult
  static func present(
    in hostView: UIView? = nil,
    provider: FKMultiPickerDataProviding,
    configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    let picker = FKMultiPicker(configuration: configuration)
    picker.bindDataProvider(provider)
    picker.onConfirmed = onConfirmed
    picker.show(in: hostView)
    return picker
  }

  /// One-line helper for showing built-in region picker.
  ///
  /// - Parameters:
  ///   - hostView: Target container view.
  ///   - configuration: Picker configuration.
  ///   - onConfirmed: Confirmation callback.
  /// - Returns: Presented picker instance for further operations.
  @discardableResult
  static func presentRegionPicker(
    in hostView: UIView? = nil,
    configuration: FKMultiPickerConfiguration = FKMultiPickerManager.shared.defaultConfiguration,
    onConfirmed: ((FKMultiPickerSelectionResult) -> Void)? = nil
  ) -> FKMultiPicker {
    present(
      in: hostView,
      nodes: FKMultiPickerBuiltInRegionDataProvider.standardRegionNodes,
      configuration: configuration,
      onConfirmed: onConfirmed
    )
  }
}
