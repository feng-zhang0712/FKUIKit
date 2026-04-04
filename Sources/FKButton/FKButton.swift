//
// FKButton.swift
//
// 自绘布局的按钮控件：多状态标题/副标题/多槽位图片/自定义视图，以及圆角、阴影、边框等。
//

import UIKit

/// 基于 `UIControl` 状态机的按钮；内容通过 `setTitle`、`setImage`、`setAppearance` 等按 `UIControl.State` 注册。
///
/// 子类化时可重写 `layoutSubviews`、`intrinsicContentSize`、`point(inside:with:)` 等（已标为 `open`）。
open class FKButton: UIControl {
  private typealias StateKey = UInt
  private typealias StatefulValues<T> = [StateKey: T]
  
  /// 按钮内容的排布轴（影响图片与标题的排列方式）。
  ///
  /// - `horizontal`：水平方向排列。
  /// - `vertical`：垂直方向排列。
  ///
  /// 在 `.textAndImage` 下决定图文相对排布；其它 `content.kind` 下影响较小或无效。
  public enum Axis {
    case horizontal
    case vertical
  }
  
  /// 图片槽位（`setImage` / `setLeadingImage` / `setTrailingImage` 的语义）。
  ///
  /// - `center`：图片居中槽位（仅在 `.imageOnly` 或 `.textAndImage` 局部需要时使用）。
  /// - `leading`：与标题相邻的“前置”图片槽位（在不同 `axis` 下会对应不同的物理方向）。
  /// - `trailing`：与标题相邻的“后置”图片槽位（在不同 `axis` 下会对应不同的物理方向）。
  public enum ImageSlot {
    case center
    case leading
    case trailing
  }
  
  public var content: FKButton.Content {
    didSet {
      applyContentLayout()
      applyTextForCurrentState()
      applyImagesForCurrentState()
      applyCustomContentForCurrentState()
      applyAppearanceForCurrentState()
    }
  }
  
  public var axis: Axis = .horizontal {
    didSet { applyAxis() }
  }
  
  private let stackView = UIStackView()

  /// 仅在 `content.kind` 为 `.textOnly` / `.textAndImage` 时创建（通过 title 容器加入层级）；
  /// 切换到 `.imageOnly` / `.custom` 时通过 `releaseTitleLabel()` 回收。
  public private(set) var titleLabel: UILabel?
  
  /// 在 `titleLabel` 下方展示的“副标题”标签。
  /// 布局方式：subtitle 永远使用约束贴在 `titleLabel` 下方。
  public private(set) var subtitleLabel: UILabel?
  
  /// 标题容器（subtitle 永远在 title 下方）。
  private var titleContainerView: UIView?
  
  /// 仅在需要对应槽位时创建；`clearImageSlot(_:)` / `releaseAllImageSlots()` 回收。
  public private(set) var imageView: UIImageView?
  public private(set) var leadingImageView: UIImageView?
  public private(set) var trailingImageView: UIImageView?

  
  private var titleLabelBottomConstraintToContainer: NSLayoutConstraint?
  private var subtitleTopConstraint: NSLayoutConstraint?
  private var subtitleBottomConstraint: NSLayoutConstraint?
  private let subtitleVerticalSpacing: CGFloat = 2

  /// 仅在 `Content.Kind.custom` 时创建；`releaseCustomContentHost()` 回收。
  private var customContentHost: FKButtonCustomContentHostView?
  private var embeddedCustomContentView: UIView?

  private var appearanceByState: StatefulValues<Appearance> = [UIControl.State.normal.rawValue: .default]

  private var titleByState: StatefulValues<Text> = [:]
  private var subtitleByState: StatefulValues<Text> = [:]
  private var customContentByState: StatefulValues<CustomContent> = [:]

  /// 按槽位存状态数据；不预分配空字典，与「视图按需创建」一致，仅在首次 `setImage` 时写入。
  private var imagesBySlotAndState: [ImageSlot: StatefulValues<Image>] = [:]
  
  private var imageConstraints: [ObjectIdentifier: [NSLayoutConstraint]] = [:]
  
  private var topConstraint: NSLayoutConstraint?
  private var leadingConstraint: NSLayoutConstraint?
  private var trailingConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  
  public init() {
    self.content = .default
    super.init(frame: .zero)
    commonInit()
  }
  
  public override init(frame: CGRect) {
    self.content = .default
    super.init(frame: frame)
    commonInit()
  }
  
  public init(content: FKButton.Content) {
    self.content = .default
    super.init(frame: .zero)
    commonInit()
  }
  
  public required init?(coder: NSCoder) {
    self.content = .default
    super.init(coder: coder)
    commonInit()
  }
  
  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .button

    stackView.spacing = 0
    stackView.alignment = .center
    stackView.isUserInteractionEnabled = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    
    topConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)
    leadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor)
    trailingConstraint = stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
    bottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
    
    topConstraint?.isActive = true
    leadingConstraint?.isActive = true
    trailingConstraint?.isActive = true
    bottomConstraint?.isActive = true

    applyAxis()
    applyContentLayout()
    applyTextForCurrentState()
    applyImagesForCurrentState()
    applyCustomContentForCurrentState()
    applyAppearanceForCurrentState()
  }
  
  // MARK: - Public — Appearance

  /// 注册指定状态下的外观；当前状态匹配时会立即应用。
  public func setAppearance(_ appearance: Appearance, for state: UIControl.State) {
    appearanceByState[state.rawValue] = appearance
    applyAppearanceForCurrentState()
  }
  
  public func appearance(for state: UIControl.State) -> Appearance? {
    appearanceByState[state.rawValue]
  }

  // MARK: - Public — Text

  /// 注册主标题文案；`nil` 清除该状态。
  public func setTitle(_ text: Text?, for state: UIControl.State) {
    if let text {
      titleByState[state.rawValue] = text
    } else {
      titleByState.removeValue(forKey: state.rawValue)
    }
    applyTextForCurrentState()
  }
  
  public func title(for state: UIControl.State) -> Text? {
    titleByState[state.rawValue]
  }
  
  /// 注册副标题；`nil` 清除该状态。
  public func setSubtitle(_ text: Text?, for state: UIControl.State) {
    if let text {
      subtitleByState[state.rawValue] = text
    } else {
      subtitleByState.removeValue(forKey: state.rawValue)
    }
    applyTextForCurrentState()
  }
  
  public func subtitle(for state: UIControl.State) -> Text? {
    subtitleByState[state.rawValue]
  }

  // MARK: - Public — Images

  /// 设置居中槽位图片（`.center`）。
  public func setImage(_ image: Image?, for state: UIControl.State) {
    setImage(image, for: state, slot: .center)
    applyImagesForCurrentState()
  }
  
  /// 设置前置侧图片槽（相对标题的 leading，随 `axis` 与布局方向映射到具体几何位置）。
  public func setLeadingImage(_ image: Image?, for state: UIControl.State) {
    setImage(image, for: state, slot: .leading)
    applyImagesForCurrentState()
  }
  
  /// 设置后置侧图片槽。
  public func setTrailingImage(_ image: Image?, for state: UIControl.State) {
    setImage(image, for: state, slot: .trailing)
    applyImagesForCurrentState()
  }
  
  /// 读取已注册的槽位图片。
  public func image(for state: UIControl.State, slot: ImageSlot) -> Image? {
    imagesBySlotAndState[slot]?[state.rawValue]
  }

  // MARK: - Public — Custom content

  /// 需 `content.kind == .custom`；`nil` 清除该状态。
  public func setCustomContent(_ content: CustomContent?, for state: UIControl.State) {
    if let content {
      customContentByState[state.rawValue] = content
    } else {
      customContentByState.removeValue(forKey: state.rawValue)
    }
    applyCustomContentForCurrentState()
  }

  public func customContent(for state: UIControl.State) -> CustomContent? {
    customContentByState[state.rawValue]
  }
  
  // MARK: - Layout
  
  open override var intrinsicContentSize: CGSize {
    let appearance = resolveAppearance()
    let insets = appearance.contentInsets
    let size = stackView.systemLayoutSizeFitting(
      CGSize(
        width: UIView.layoutFittingCompressedSize.width,
        height: UIView.layoutFittingCompressedSize.height
      ),
      withHorizontalFittingPriority: .defaultLow,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(
      width: size.width + insets.leading + insets.trailing,
      height: size.height + insets.top + insets.bottom
    )
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    applyCornerMetrics(using: resolveAppearance())
  }
  
  open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    bounds.insetBy(dx: 0, dy: -6).contains(point)
  }
  
  // MARK: - State
  
  open override var isEnabled: Bool {
    didSet {
      applyTextForCurrentState()
      applyImagesForCurrentState()
      applyCustomContentForCurrentState()
      applyAppearanceForCurrentState()
    }
  }
  
  open override var isSelected: Bool {
    didSet {
      applyTextForCurrentState()
      applyImagesForCurrentState()
      applyCustomContentForCurrentState()
      applyAppearanceForCurrentState()
      accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
  }
  
  open override var isHighlighted: Bool {
    didSet {
      applyTextForCurrentState()
      applyImagesForCurrentState()
      applyCustomContentForCurrentState()
      applyAppearanceForCurrentState()
      UIView.animate(withDuration: 0.12) {
        self.alpha = self.isHighlighted ? 0.88 : 1
      }
    }
  }
  
  // MARK: - Private
  
  private func applyAxis() {
    switch axis {
    case .horizontal:
      stackView.axis = .horizontal
    case .vertical:
      stackView.axis = .vertical
    }
  }

  // MARK: - Title & Subtitle lifecycle (按需创建 / 及时回收)

  private func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  private func titleLabelIfNeeded() -> UILabel {
    if let existing = titleLabel { return existing }
    let label = makeTitleLabel()
    titleLabel = label
    return label
  }

  private func releaseTitleLabel() {
    guard let label = titleLabel else { return }
    // 先清理副标题，避免内部约束残留。
    releaseSubtitleLabel()
    titleContainerView?.removeFromSuperview()
    titleContainerView = nil
    titleLabelBottomConstraintToContainer = nil
    subtitleTopConstraint = nil
    subtitleBottomConstraint = nil
    label.removeFromSuperview()
    label.text = nil
    label.attributedText = nil
    titleLabel = nil
  }
  
  private func titleContainerViewIfNeeded() -> UIView {
    if let existing = titleContainerView { return existing }
    let container = UIView()
    container.isUserInteractionEnabled = false
    container.backgroundColor = .clear
    titleContainerView = container
    
    let label = titleLabelIfNeeded()
    if label.superview !== container {
      container.addSubview(label)
    }
    label.translatesAutoresizingMaskIntoConstraints = false
    
    let top = label.topAnchor.constraint(equalTo: container.topAnchor)
    let leading = label.leadingAnchor.constraint(equalTo: container.leadingAnchor)
    let trailing = label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    let bottom = label.bottomAnchor.constraint(equalTo: container.bottomAnchor) // subtitle 不存在时使用
    titleLabelBottomConstraintToContainer = bottom
    NSLayoutConstraint.activate([top, leading, trailing, bottom])
    return container
  }

  // MARK: - Subviews
  
  private func makeImageView() -> UIImageView {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFit
    imgView.setContentHuggingPriority(.required, for: .vertical)
    imgView.setContentHuggingPriority(.required, for: .horizontal)
    return imgView
  }

  private func makeSubtitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  private func subtitleLabelIfNeeded() -> UILabel {
    if let existing = subtitleLabel { return existing }
    let label = makeSubtitleLabel()
    subtitleLabel = label
    
    let container = titleContainerViewIfNeeded()
    if label.superview !== container {
      container.addSubview(label)
    }
    label.translatesAutoresizingMaskIntoConstraints = false
    
    // subtitle 加入后：title 底部不再直接贴 container bottom，而是由 subtitle 承接。
    titleLabelBottomConstraintToContainer?.isActive = false
    
    let leading = label.leadingAnchor.constraint(equalTo: container.leadingAnchor)
    let trailing = label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    let top = label.topAnchor.constraint(equalTo: titleLabelIfNeeded().bottomAnchor, constant: subtitleVerticalSpacing)
    let bottom = label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    
    subtitleTopConstraint = top
    subtitleBottomConstraint = bottom
    
    NSLayoutConstraint.activate([leading, trailing, top, bottom])
    return label
  }

  private func releaseSubtitleLabel() {
    guard let label = subtitleLabel else { return }
    subtitleTopConstraint?.isActive = false
    subtitleBottomConstraint?.isActive = false
    subtitleTopConstraint = nil
    subtitleBottomConstraint = nil
    
    label.removeFromSuperview()
    label.text = nil
    label.attributedText = nil
    subtitleLabel = nil
    
    // subtitle 销毁后：重新启用 title 作为 container 底部锚点
    titleLabelBottomConstraintToContainer?.isActive = true
  }

  private func imageViewIfNeeded(for slot: ImageSlot) -> UIImageView {
    switch slot {
    case .center:
      if let existing = imageView { return existing }
      let v = makeImageView()
      imageView = v
      return v
    case .leading:
      if let existing = leadingImageView { return existing }
      let v = makeImageView()
      leadingImageView = v
      return v
    case .trailing:
      if let existing = trailingImageView { return existing }
      let v = makeImageView()
      trailingImageView = v
      return v
    }
  }

  private func clearImageSlot(_ slot: ImageSlot) {
    let view: UIImageView?
    switch slot {
    case .center: view = imageView
    case .leading: view = leadingImageView
    case .trailing: view = trailingImageView
    }
    guard let imageView = view else { return }
    applyImage(nil, to: imageView)
    imageView.removeFromSuperview()
    switch slot {
    case .center: self.imageView = nil
    case .leading: leadingImageView = nil
    case .trailing: trailingImageView = nil
    }
  }

  private func releaseAllImageSlots() {
    clearImageSlot(.center)
    clearImageSlot(.leading)
    clearImageSlot(.trailing)
  }

  private func customContentHostIfNeeded() -> FKButtonCustomContentHostView {
    if let existing = customContentHost { return existing }
    let host = FKButtonCustomContentHostView()
    host.isUserInteractionEnabled = false
    host.backgroundColor = .clear
    customContentHost = host
    return host
  }

  private func releaseCustomContentHost() {
    embeddedCustomContentView?.removeFromSuperview()
    embeddedCustomContentView = nil
    customContentHost?.subviews.forEach { $0.removeFromSuperview() }
    customContentHost?.removeFromSuperview()
    customContentHost = nil
  }
  
  private func applyContentLayout() {
    stackView.arrangedSubviews.forEach {
      $0.removeFromSuperview()
    }
    
    switch content.kind {
    case .textOnly:
      stackView.spacing = 0
      stackView.addArrangedSubview(titleContainerViewIfNeeded())
    case .imageOnly:
      stackView.spacing = 0
      stackView.addArrangedSubview(imageViewIfNeeded(for: .center))
    case .textAndImage(let alignment):
      switch alignment {
      case .leading:
        stackView.addArrangedSubview(imageViewIfNeeded(for: .leading))
        stackView.addArrangedSubview(titleContainerViewIfNeeded())
      case .trailing:
        stackView.addArrangedSubview(titleContainerViewIfNeeded())
        stackView.addArrangedSubview(imageViewIfNeeded(for: .trailing))
      case .bothSides:
        stackView.addArrangedSubview(imageViewIfNeeded(for: .leading))
        stackView.addArrangedSubview(titleContainerViewIfNeeded())
        stackView.addArrangedSubview(imageViewIfNeeded(for: .trailing))
      }
    case .custom:
      stackView.addArrangedSubview(customContentHostIfNeeded())
    }
  }
  
  private func applyAppearanceForCurrentState() {
    let appearance = resolveAppearance()

    alpha = appearance.alpha
    backgroundColor = appearance.backgroundColor
    layer.borderWidth = appearance.borderWidth
    layer.borderColor = appearance.borderColor.cgColor
    layer.cornerCurve = appearance.cornerCurve
    layer.maskedCorners = appearance.maskedCorners
    
    if let shadow = appearance.shadow {
      layer.shadowOffset = shadow.offset
      layer.shadowRadius = shadow.radius
      layer.shadowOpacity = shadow.opacity
      layer.shadowColor = shadow.color.cgColor
      layer.masksToBounds = false
    } else {
      layer.shadowOpacity = 0
      layer.masksToBounds = true
    }
    
    let insets = appearance.contentInsets
    topConstraint?.constant = insets.top
    leadingConstraint?.constant = insets.leading
    trailingConstraint?.constant = -insets.trailing
    bottomConstraint?.constant = -insets.bottom
    
    applyCornerMetrics(using: appearance)
    
    invalidateIntrinsicContentSize()
  }
  
  private func applyCornerMetrics(using appearance: Appearance) {
    switch appearance.corner {
    case .none:
      layer.cornerRadius = 0
    case let .fixed(radius):
      layer.cornerRadius = radius
    case .capsule:
      layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    if let clipsToBounds = appearance.clipsToBounds {
      self.clipsToBounds = clipsToBounds
    } else {
      self.clipsToBounds = (appearance.shadow == nil)
    }
  }
  
  private func applyTextForCurrentState() {
    switch content.kind {
    case .textOnly, .textAndImage:
      let title = resolveTitleElement()
      applyTitle(title)
      applySubtitleForCurrentState()
    case .imageOnly:
      releaseTitleLabel()
      releaseSubtitleLabel()
      let image = resolveImageElement(for: .center)
      accessibilityLabel = image?.accessibilityLabel
      accessibilityHint = image?.accessibilityHint
    case .custom:
      releaseTitleLabel()
      releaseSubtitleLabel()
      let customView = resolveCustomContent()?.view
      accessibilityLabel = customView?.accessibilityLabel
      accessibilityHint = customView?.accessibilityHint
    }
  }

  // MARK: - Subviews rendering

  private func resolveSubtitleElement() -> Text? {
    resolveFromStateMap(subtitleByState)
  }

  private func subtitleHasRenderableContent(_ subtitle: Text) -> Bool {
    if subtitle.attributedText != nil { return true }
    if let text = subtitle.text { return !text.isEmpty }
    return false
  }

  private func applySubtitleForCurrentState() {
    guard let subtitle = resolveSubtitleElement(), subtitleHasRenderableContent(subtitle) else {
      releaseSubtitleLabel()
      return
    }
    applySubtitle(subtitle)
  }
  
  private func applyImagesForCurrentState() {
    switch content.kind {
    case .imageOnly:
      clearImageSlot(.leading)
      clearImageSlot(.trailing)
      applyImage(resolveImageElement(for: .center), to: imageViewIfNeeded(for: .center))
      stackView.spacing = 0
    case let .textAndImage(alignment):
      switch alignment {
      case .leading:
        clearImageSlot(.center)
        let leading = resolveImageElement(for: .leading)
        applyImage(leading, to: imageViewIfNeeded(for: .leading))
        clearImageSlot(.trailing)
        stackView.spacing = leading?.spacingToTitle ?? 0
      case .trailing:
        clearImageSlot(.center)
        clearImageSlot(.leading)
        let trailing = resolveImageElement(for: .trailing)
        applyImage(trailing, to: imageViewIfNeeded(for: .trailing))
        stackView.spacing = trailing?.spacingToTitle ?? 0
      case .bothSides:
        clearImageSlot(.center)
        let leading = resolveImageElement(for: .leading)
        let trailing = resolveImageElement(for: .trailing)
        applyImage(leading, to: imageViewIfNeeded(for: .leading))
        applyImage(trailing, to: imageViewIfNeeded(for: .trailing))
        stackView.spacing = max(leading?.spacingToTitle ?? 0, trailing?.spacingToTitle ?? 0)
      }
    case .textOnly:
      releaseAllImageSlots()
      stackView.spacing = 0
    case .custom:
      releaseAllImageSlots()
      stackView.spacing = 0
    }
  }

  private func resolveCustomContent() -> CustomContent? {
    resolveFromStateMap(customContentByState)
  }

  private func applyCustomContentForCurrentState() {
    guard case .custom = content.kind else {
      releaseCustomContentHost()
      return
    }

    let element = resolveCustomContent()
    let newView = element?.view

    // 当前仅单槽「纯自定义」布局；`spacingToAdjacentContent` 预留给未来图文混排扩展。
    stackView.spacing = element?.spacingToAdjacentContent ?? 0

    let host = customContentHostIfNeeded()

    if embeddedCustomContentView !== newView {
      embeddedCustomContentView?.removeFromSuperview()
      embeddedCustomContentView = nil

      if let view = newView {
        host.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          view.topAnchor.constraint(equalTo: host.topAnchor),
          view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
          view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
          view.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        embeddedCustomContentView = view
      }
    }

    host.invalidateIntrinsicContentSize()
    host.isHidden = (newView == nil)
    invalidateIntrinsicContentSize()
  }

  private var stateResolutionOrder: [UIControl.State] {
    // 解析顺序：disabled → selected → highlighted → normal
    if !isEnabled { return [.disabled, .normal] }
    if isSelected { return [.selected, .normal] }
    if isHighlighted { return [.highlighted, .normal] }
    return [.normal]
  }

  private func resolveFromStateMap<T>(_ map: StatefulValues<T>) -> T? {
    for state in stateResolutionOrder {
      if let value = map[state.rawValue] {
        return value
      }
    }
    return nil
  }

  private func resolveAppearance() -> Appearance {
    resolveFromStateMap(appearanceByState) ?? .default
  }

  private func resolveTitleElement() -> Text {
    resolveFromStateMap(titleByState) ?? .default
  }

  private func resolveImageElement(for slot: ImageSlot) -> Image? {
    guard let map = imagesBySlotAndState[slot] else { return nil }
    return resolveFromStateMap(map)
  }

  private func setImage(_ image: Image?, for state: UIControl.State, slot: ImageSlot) {
    if var map = imagesBySlotAndState[slot] {
      if let image {
        map[state.rawValue] = image
      } else {
        map.removeValue(forKey: state.rawValue)
      }
      imagesBySlotAndState[slot] = map
    } else {
      imagesBySlotAndState[slot] = image.map { [state.rawValue: $0] } ?? [:]
    }
  }

  private func applyTitle(_ title: Text) {
    let label = titleLabelIfNeeded()
    label.textAlignment = title.alignment
    label.numberOfLines = title.numberOfLines
    label.lineBreakMode = title.lineBreakMode
    label.adjustsFontSizeToFitWidth = title.adjustsFontSizeToFitWidth
    label.minimumScaleFactor = title.minimumScaleFactor
    label.allowsDefaultTighteningForTruncation = title.allowsDefaultTighteningForTruncation
    label.shadowColor = title.shadowColor
    label.shadowOffset = title.shadowOffset

    if let accessibilityLabel = title.accessibilityLabel {
      self.accessibilityLabel = accessibilityLabel
    }
    accessibilityHint = title.accessibilityHint

    if let attributed = title.attributedText {
      label.attributedText = attributed
      if self.accessibilityLabel == nil {
        self.accessibilityLabel = attributed.string
      }
      return
    }

    var text = title.text ?? ""
    if title.uppercased { text = text.uppercased() }
    if title.lowercased { text = text.lowercased() }

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = title.alignment
    paragraph.lineBreakMode = title.lineBreakMode
    if title.lineSpacing > 0 {
      paragraph.lineSpacing = title.lineSpacing
    }
    if title.lineHeight > 0 {
      paragraph.minimumLineHeight = title.lineHeight
      paragraph.maximumLineHeight = title.lineHeight
    }

    let attributes: [NSAttributedString.Key: Any] = [
      .font: title.font,
      .foregroundColor: title.color,
      .kern: title.kerning,
      .paragraphStyle: paragraph,
    ]
    label.attributedText = NSAttributedString(string: text, attributes: attributes)
    if self.accessibilityLabel == nil {
      self.accessibilityLabel = text
    }
  }

  private func applySubtitle(_ subtitle: Text) {
    let label = subtitleLabelIfNeeded()
    label.textAlignment = subtitle.alignment
    label.numberOfLines = subtitle.numberOfLines
    label.lineBreakMode = subtitle.lineBreakMode
    label.adjustsFontSizeToFitWidth = subtitle.adjustsFontSizeToFitWidth
    label.minimumScaleFactor = subtitle.minimumScaleFactor
    label.allowsDefaultTighteningForTruncation = subtitle.allowsDefaultTighteningForTruncation
    label.shadowColor = subtitle.shadowColor
    label.shadowOffset = subtitle.shadowOffset

    if let attributed = subtitle.attributedText {
      label.attributedText = attributed
      return
    }

    var text = subtitle.text ?? ""
    if subtitle.uppercased { text = text.uppercased() }
    if subtitle.lowercased { text = text.lowercased() }

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = subtitle.alignment
    paragraph.lineBreakMode = subtitle.lineBreakMode
    if subtitle.lineSpacing > 0 {
      paragraph.lineSpacing = subtitle.lineSpacing
    }
    if subtitle.lineHeight > 0 {
      paragraph.minimumLineHeight = subtitle.lineHeight
      paragraph.maximumLineHeight = subtitle.lineHeight
    }

    let attributes: [NSAttributedString.Key: Any] = [
      .font: subtitle.font,
      .foregroundColor: subtitle.color,
      .kern: subtitle.kerning,
      .paragraphStyle: paragraph,
    ]
    label.attributedText = NSAttributedString(string: text, attributes: attributes)
  }

  private func applyImage(_ element: Image?, to imageView: UIImageView) {
    guard let element else {
      imageView.image = nil
      imageView.alpha = 0
      deactivateImageConstraints(for: imageView)
      return
    }

    let image: UIImage? = {
      if let image = element.image {
        return image
      }
      guard let systemName = element.systemName else { return nil }
      if let symbolConfiguration = element.symbolConfiguration {
        return UIImage(systemName: systemName, withConfiguration: symbolConfiguration)
      }
      return UIImage(systemName: systemName)
    }()

    var rendered = image?.withRenderingMode(element.renderingMode)
    if let symbolConfiguration = element.symbolConfiguration {
      rendered = rendered?.applyingSymbolConfiguration(symbolConfiguration)
    }

    imageView.image = rendered
    imageView.alpha = element.alpha
    imageView.tintColor = element.tintColor
    imageView.contentMode = element.contentMode
    imageView.semanticContentAttribute = element.flipsForRightToLeftLayoutDirection ? .unspecified : .forceLeftToRight
    imageView.isHidden = (rendered == nil)
    imageView.alpha = (rendered == nil) ? 0 : element.alpha

    deactivateImageConstraints(for: imageView)
    var constraints: [NSLayoutConstraint] = []
    imageView.translatesAutoresizingMaskIntoConstraints = false

    if let fixedSize = element.fixedSize {
      constraints.append(imageView.widthAnchor.constraint(equalToConstant: fixedSize.width))
      constraints.append(imageView.heightAnchor.constraint(equalToConstant: fixedSize.height))
    } else {
      if let minimum = element.minimumSize {
        constraints.append(imageView.widthAnchor.constraint(greaterThanOrEqualToConstant: minimum.width))
        constraints.append(imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimum.height))
      }
      if let maximum = element.maximumSize {
        constraints.append(imageView.widthAnchor.constraint(lessThanOrEqualToConstant: maximum.width))
        constraints.append(imageView.heightAnchor.constraint(lessThanOrEqualToConstant: maximum.height))
      }
    }

    NSLayoutConstraint.activate(constraints)
    imageConstraints[ObjectIdentifier(imageView)] = constraints
  }

  private func deactivateImageConstraints(for imageView: UIImageView) {
    let key = ObjectIdentifier(imageView)
    if let constraints = imageConstraints[key] {
      NSLayoutConstraint.deactivate(constraints)
      imageConstraints[key] = nil
    }
  }
}

// MARK: - Custom content sizing

/// 自定义内容宿主：单个子视图贴边填充，向 `UIStackView` 上报 fitting / intrinsic 尺寸。
private final class FKButtonCustomContentHostView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    isOpaque = false
  }

  override func didAddSubview(_ subview: UIView) {
    super.didAddSubview(subview)
    invalidateIntrinsicContentSize()
  }

  override func willRemoveSubview(_ subview: UIView) {
    super.willRemoveSubview(subview)
    invalidateIntrinsicContentSize()
  }

  override var intrinsicContentSize: CGSize {
    guard let subview = subviews.first else {
      return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    let fitted = subview.systemLayoutSizeFitting(
      CGSize(width: UIView.layoutFittingCompressedSize.width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .fittingSizeLevel,
      verticalFittingPriority: .fittingSizeLevel
    )
    if fitted.width > 0.5, fitted.height > 0.5 {
      return fitted
    }
    let intrinsic = subview.intrinsicContentSize
    let width = intrinsic.width > 0 ? intrinsic.width : UIView.noIntrinsicMetric
    let height = intrinsic.height > 0 ? intrinsic.height : UIView.noIntrinsicMetric
    if width != UIView.noIntrinsicMetric || height != UIView.noIntrinsicMetric {
      return CGSize(width: width, height: height)
    }
    return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
  }
}
