import UIKit

@MainActor
final class FKTabBarItemCell: UICollectionViewCell {
  // MARK: - Model

  /// Immutable rendering input for a tab cell.
  ///
  /// The model is designed so the tab bar can re-apply it frequently during interactive progress
  /// without touching global state. `selectionProgress` is expected to be clamped to \([0, 1]\).
  struct Model {
    var item: FKTabBarItem
    var isSelected: Bool
    var appearance: FKTabBarAppearance
    var overflowMode: FKTabBarTitleOverflowMode
    var selectionProgress: CGFloat
    var layoutDirection: FKTabBarItemLayoutDirection
    var rtlBehavior: FKTabBarRTLBehavior
    var longPressMinimumDuration: TimeInterval
    var isLongPressEnabled: Bool
    var maximumTitleLines: Int
  }

  private enum ContentKind {
    case textOnly
    case imageOnly
    case textAndImage
    case custom
  }

  private let tabButton = FKButton()
  private var customBadgeView: UIView?
  var onTap: ((FKButton) -> Void)?
  var onLongPress: ((FKButton) -> Void)?

  /// Returns the internal interactive button for same-module integrations.
  ///
  /// We intentionally keep this internal (instead of exposing a public mutable property on the cell)
  /// to preserve reuse invariants and avoid external replacement of the button instance.
  func interactiveButtonForIntegration() -> FKButton { tabButton }

  // MARK: - Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Reuse must reset badge hosting and custom content, otherwise stale views may leak across items
    // when the collection view recycles cells during fast scrolling.
    clearBadges()
    customBadgeView?.removeFromSuperview()
    customBadgeView = nil
    tabButton.setCustomContent(nil, for: .normal)
    tabButton.setCustomContent(nil, for: .selected)
    tabButton.setCustomContent(nil, for: .disabled)
    onTap = nil
    onLongPress = nil
    tabButton.onLongPressBegan = nil
    tabButton.onLongPressEnded = nil
  }

  // MARK: - Render

  func apply(
    _ model: Model,
    customBadgeProvider: ((FKTabBarItem) -> UIView?)?,
    customContentViewProvider: ((FKTabBarItem) -> UIView?)?,
    badgeConfiguration: FKBadgeConfiguration?,
    badgeAnimation: FKBadgeAnimation,
    buttonConfigurator: ((FKButton, FKTabBarItem, Bool) -> Void)?
  ) {
    let appearance = model.appearance
    let item = model.item
    let selected = model.isSelected
    let progress = max(0, min(1, model.selectionProgress))

    let contentKind = resolvedContentKind(for: item)
    applyContent(contentKind, selected: selected, item: item, customContentViewProvider: customContentViewProvider)
    applyLayoutDirection(model.layoutDirection)
    applyRTLBehavior(model.rtlBehavior)
    tabButton.longPressMinimumDuration = model.longPressMinimumDuration

    // Progressive font transition is approximated to avoid synthesizing fonts per frame.
    // When progress crosses midpoint, we switch to selected typography.
    let useSelectedFont = progress >= 0.5 ? true : selected
    let baseFont = useSelectedFont ? appearance.typography.selectedFont : appearance.typography.normalFont

    let textColor: UIColor
    let iconColor: UIColor
    if !item.isEnabled {
      textColor = appearance.colors.disabledText
      iconColor = appearance.colors.disabledIcon
    } else if selected || progress > 0 {
      // During interaction, interpolate colors to match `selectionProgress`.
      textColor = interpolate(from: appearance.colors.normalText, to: appearance.colors.selectedText, progress: progress)
      iconColor = interpolate(from: appearance.colors.normalIcon, to: appearance.colors.selectedIcon, progress: progress)
    } else {
      textColor = appearance.colors.normalText
      iconColor = appearance.colors.normalIcon
    }
    let titleText = resolvedTitle(for: item, isSelected: selected)
    let lineBreakMode: NSLineBreakMode
    let adjustsFontSizeToFitWidth: Bool
    let minimumScaleFactor: CGFloat

    if titleText.isEmpty {
      lineBreakMode = .byClipping
      adjustsFontSizeToFitWidth = false
      minimumScaleFactor = 1
    } else {
      switch model.overflowMode {
      case .truncate, .automaticWidth, .fixedWidth:
        lineBreakMode = .byTruncatingTail
        adjustsFontSizeToFitWidth = false
        minimumScaleFactor = 1
      case .shrink(let factor):
        lineBreakMode = .byClipping
        adjustsFontSizeToFitWidth = true
        minimumScaleFactor = max(0.5, min(1.0, factor))
      case .wrap:
        lineBreakMode = .byWordWrapping
        adjustsFontSizeToFitWidth = false
        minimumScaleFactor = 1
      }
    }

    tabButton.isEnabled = item.isEnabled
    tabButton.isSelected = selected
    let sharedAppearance = FKButton.Appearance(
      backgroundColor: .clear,
      contentInsets: .init(top: 6, leading: 8, bottom: 6, trailing: 8)
    )
    tabButton.setAppearance(sharedAppearance, for: .normal)
    tabButton.setAppearance(sharedAppearance, for: .selected)
    tabButton.setAppearance(sharedAppearance, for: .disabled)
    let label = FKButton.LabelAttributes(
      text: titleText,
      font: baseFont,
      color: textColor,
      alignment: .center,
      numberOfLines: max(1, model.maximumTitleLines),
      lineBreakMode: lineBreakMode,
      adjustsFontForContentSizeCategory: appearance.typography.adjustsForContentSizeCategory,
      textStyle: .subheadline,
      adjustsFontSizeToFitWidth: adjustsFontSizeToFitWidth,
      minimumScaleFactor: minimumScaleFactor
    )
    tabButton.setTitle(label, for: .normal)
    tabButton.setTitle(label, for: .selected)
    tabButton.setTitle(label, for: .disabled)

    // Subtitle configuration priority:
    // item override > global appearance.
    if let subtitleConfiguration = item.subtitle {
      let subtitleState = subtitleConfiguration.resolved(isSelected: selected, isEnabled: item.isEnabled)
      if let subtitle = subtitleState.text, !subtitle.isEmpty {
        let subtitleColor: UIColor
        if !item.isEnabled {
          subtitleColor = subtitleState.style.color
        } else if selected || progress > 0 {
          let normalColor = item.subtitle?.normal.style.color ?? subtitleState.style.color
          let selectedColor = item.subtitle?.selected?.style.color ?? normalColor
          subtitleColor = interpolate(from: normalColor, to: selectedColor, progress: progress)
        } else {
          subtitleColor = subtitleState.style.color
        }
        let attrs = FKButton.LabelAttributes(
          text: subtitle,
          font: subtitleState.style.font,
          color: subtitleColor,
          alignment: subtitleState.style.alignment,
          numberOfLines: subtitleState.style.numberOfLines,
          lineBreakMode: subtitleState.style.lineBreakMode,
          adjustsFontForContentSizeCategory: subtitleState.style.adjustsForContentSizeCategory,
          textStyle: .caption2,
          adjustsFontSizeToFitWidth: subtitleState.style.adjustsFontSizeToFitWidth,
          minimumScaleFactor: subtitleState.style.minimumScaleFactor,
          contentInsets: .init(
            top: item.subtitle?.spacingToNextText ?? 0,
            leading: subtitleState.style.contentInsets.leading,
            bottom: subtitleState.style.contentInsets.bottom,
            trailing: subtitleState.style.contentInsets.trailing
          )
        )
        tabButton.setSubtitle(attrs, for: .normal)
        tabButton.setSubtitle(attrs, for: .selected)
        tabButton.setSubtitle(attrs, for: .disabled)
      } else {
        tabButton.setSubtitle(nil, for: .normal)
        tabButton.setSubtitle(nil, for: .selected)
        tabButton.setSubtitle(nil, for: .disabled)
      }
    } else {
      tabButton.setSubtitle(nil, for: .normal)
      tabButton.setSubtitle(nil, for: .selected)
      tabButton.setSubtitle(nil, for: .disabled)
    }
    tabButton.tintColor = iconColor
    // Customizer runs after default styling so hosts can override only what they need.
    buttonConfigurator?(tabButton, item, selected)

    // Accessibility is hosted by `FKButton` so VoiceOver focus matches the tappable element.
    tabButton.isAccessibilityElement = true
    tabButton.accessibilityLabel = item.accessibilityLabel ?? item.title.normal.text ?? item.id
    tabButton.accessibilityHint = item.accessibilityHint
    var traits: UIAccessibilityTraits = [.button]
    if selected { traits.insert(.selected) }
    if !item.isEnabled { traits.insert(.notEnabled) }
    tabButton.accessibilityTraits = traits
    tabButton.accessibilityValue = resolvedAccessibilityValue(
      item: item,
      isSelected: selected
    )

    applyBadge(
      item.badge,
      item: item,
      customBadgeProvider: customBadgeProvider,
      badgeConfiguration: badgeConfiguration,
      badgeAnimation: badgeAnimation
    )

    // Long-press is opt-in. Keeping callbacks nil avoids interfering with normal taps.
    if model.isLongPressEnabled {
      tabButton.onLongPressBegan = { [weak self] in
        guard let self else { return }
        self.onLongPress?(self.tabButton)
      }
    } else {
      tabButton.onLongPressBegan = nil
    }
  }

  // MARK: - View Setup

  private func setup() {
    // Avoid inheriting superview/readable margins. During rotation/split view, UIKit can change
    // effective layout margins, which would unintentionally shrink the button's available width
    // and can trigger constraint conflicts inside FKButton's internal stack layout.
    contentView.preservesSuperviewLayoutMargins = false
    contentView.layoutMargins = .init(top: 6, left: 10, bottom: 6, right: 10)
    tabButton.translatesAutoresizingMaskIntoConstraints = false
    tabButton.isUserInteractionEnabled = true
    tabButton.contentHorizontalAlignment = .center
    tabButton.contentVerticalAlignment = .center
    contentView.addSubview(tabButton)

    isAccessibilityElement = false
    contentView.isAccessibilityElement = false

    tabButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    tabButton.addTarget(self, action: #selector(handleTap), for: .primaryActionTriggered)

    NSLayoutConstraint.activate([
      tabButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      tabButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      tabButton.topAnchor.constraint(equalTo: contentView.topAnchor),
      tabButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @objc private func handleTap() {
    onTap?(tabButton)
  }

  // MARK: - Badge

  private func applyBadge(
    _ badge: FKTabBarBadgeConfiguration,
    item: FKTabBarItem,
    customBadgeProvider: ((FKTabBarItem) -> UIView?)?,
    badgeConfiguration: FKBadgeConfiguration?,
    badgeAnimation: FKBadgeAnimation
  ) {
    clearBadges()
    customBadgeView?.removeFromSuperview()
    customBadgeView = nil

    // Badge anchor resolution is centralized to keep one single source of truth.
    let target = FKTabBarBadgeAnchorResolver.resolveTargetView(button: tabButton)
    if let badgeConfiguration {
      target.fk_badge.configuration = badgeConfiguration
    }
    target.fk_badge.setAnchor(badge.anchor, offset: badge.offset)
    if badge.avoidsClipping {
      // Some badge offsets intentionally extend beyond the cell bounds (e.g. count bubble).
      // Allowing overflow is opt-in to keep scrolling performance predictable by default.
      contentView.clipsToBounds = false
      clipsToBounds = false
    }

    switch badge.state.resolved(isSelected: item.isEnabled && tabButton.isSelected, isEnabled: item.isEnabled) {
    case .none:
      break
    case .dot:
      target.fk_badge.showDot(animated: false, animation: badgeAnimation)
    case .count(let count):
      target.fk_badge.showCount(count, animated: false, animation: badgeAnimation)
    case .text(let text):
      target.fk_badge.showText(text, animated: false, animation: badgeAnimation)
    case .custom:
      guard let custom = customBadgeProvider?(item) else { return }
      custom.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(custom)
      NSLayoutConstraint.activate([
        custom.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
        custom.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
      ])
      customBadgeView = custom
    }
  }

  func contentFrame(in targetView: UIView) -> CGRect {
    // Used by indicator follow modes that want to track content rather than full item frame.
    return targetView.convert(tabButton.frame, from: contentView)
  }

  // MARK: - Content

  private func applyContent(
    _ content: ContentKind,
    selected: Bool,
    item: FKTabBarItem,
    customContentViewProvider: ((FKTabBarItem) -> UIView?)?
  ) {
    // Always clear previous state before applying new content; FKButton stores per-state values.
    let states: [UIControl.State] = [.normal, .selected, .disabled]
    states.forEach {
      tabButton.setCenterImage(nil, for: $0)
      tabButton.setLeadingImage(nil, for: $0)
      tabButton.setTrailingImage(nil, for: $0)
      tabButton.setCustomContent(nil, for: $0)
    }

    switch content {
    case .textOnly:
      tabButton.content = .textOnly
    case .imageOnly:
      tabButton.content = .imageOnly
      applyImageConfiguration(item.image, item: item)
    case .textAndImage:
      // Use semantic "leading" slot instead of hard-coded left so RTL can mirror naturally.
      tabButton.content = .textAndImage(.leading)
      applyImageConfiguration(item.image, item: item, slot: .leading)
    case .custom:
      tabButton.content = .custom
      // Host provides the view. We reuse the same view across control states so selection does not
      // cause view replacement (which can be visually noisy).
      let normalContent = FKButton.CustomContent(view: customContentViewProvider?(item), spacingToAdjacentContent: 0)
      tabButton.setCustomContent(normalContent, for: .normal)
      tabButton.setCustomContent(normalContent, for: .selected)
      tabButton.setCustomContent(normalContent, for: .disabled)
    }
  }

  private func applyLayoutDirection(_ direction: FKTabBarItemLayoutDirection) {
    switch direction {
    case .horizontal:
      tabButton.axis = .horizontal
    case .vertical:
      tabButton.axis = .vertical
    }
  }

  private func applyRTLBehavior(_ behavior: FKTabBarRTLBehavior) {
    switch behavior {
    case .automatic:
      tabButton.semanticContentAttribute = .unspecified
    case .forceLeftToRight:
      tabButton.semanticContentAttribute = .forceLeftToRight
    case .forceRightToLeft:
      tabButton.semanticContentAttribute = .forceRightToLeft
    }
  }

  private func resolvedTitle(for item: FKTabBarItem, isSelected: Bool) -> String {
    let state = item.title.resolved(isSelected: isSelected, isEnabled: item.isEnabled)
    return state.text ?? ""
  }

  private func clearBadges() {
    // Reset clipping defaults because some badge placements require overflow.
    contentView.clipsToBounds = true
    clipsToBounds = true
    [tabButton, tabButton.imageView, tabButton.leadingImageView, tabButton.trailingImageView].forEach { view in
      view?.fk_badge.clear(animated: false)
    }
  }

  private func resolveImage(_ source: FKTabBarImageSource?) -> UIImage? {
    guard let source else { return nil }
    switch source {
    case .image(let image):
      return image
    case .systemSymbol(let name):
      return UIImage(systemName: name)
    case .asset(let name, let bundle):
      let resolved = UIImage(named: name, in: bundle, compatibleWith: nil)
      return resolved
    case .remote(_, let placeholder):
      return placeholder
    }
  }

  private func resolvedAccessibilityValue(item: FKTabBarItem, isSelected: Bool) -> String? {
    let selectedToken = isSelected ? "Selected" : nil
    if let explicit = item.badge.accessibilityValue, !explicit.isEmpty {
      if let selectedToken {
        return "\(selectedToken), \(explicit)"
      }
      return explicit
    }
    let badgeToken: String? = {
      switch item.badge.state.resolved(isSelected: isSelected, isEnabled: item.isEnabled) {
      case .none:
        return nil
      case .dot:
        return "Badge"
      case .count(let value):
        return "Badge \(max(0, value))"
      case .text(let text):
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Badge" : "Badge \(trimmed)"
      case .custom:
        return "Custom badge"
      }
    }()
    switch (selectedToken, badgeToken) {
    case let (selected?, badge?):
      return "\(selected), \(badge)"
    case let (selected?, nil):
      return selected
    case let (nil, badge?):
      return badge
    case (nil, nil):
      return nil
    }
  }

  // MARK: - Private Helpers

  private func resolvedContentKind(for item: FKTabBarItem) -> ContentKind {
    if item.customContentIdentifier != nil { return .custom }
    let hasText = !(item.title.normal.text ?? "").isEmpty
    let hasImage = item.image?.normal.source != nil
    if hasText && hasImage { return .textAndImage }
    if hasImage { return .imageOnly }
    return .textOnly
  }

  private func applyImageConfiguration(_ configuration: FKTabBarImageConfiguration?, item: FKTabBarItem, slot: FKButton.ImageSlot = .center) {
    guard let configuration else { return }
    let normalState = configuration.normal
    let selectedState = configuration.selected ?? normalState
    let disabledState = configuration.disabled ?? normalState
    let normalImage = FKButton.ImageAttributes(
      image: resolveImage(normalState.source),
      tintColor: normalState.style.tintColor,
      fixedSize: normalState.style.fixedSize,
      spacingToTitle: normalState.style.spacingToTitle
    )
    let selectedImage = FKButton.ImageAttributes(
      image: resolveImage(selectedState.source),
      tintColor: selectedState.style.tintColor,
      fixedSize: selectedState.style.fixedSize,
      spacingToTitle: selectedState.style.spacingToTitle
    )
    let disabledImage = FKButton.ImageAttributes(
      image: resolveImage(disabledState.source),
      tintColor: disabledState.style.tintColor,
      fixedSize: disabledState.style.fixedSize,
      spacingToTitle: disabledState.style.spacingToTitle
    )
    switch slot {
    case .center:
      tabButton.setCenterImage(normalImage, for: .normal)
      tabButton.setCenterImage(selectedImage, for: .selected)
      tabButton.setCenterImage(disabledImage, for: .disabled)
    case .leading:
      tabButton.setLeadingImage(normalImage, for: .normal)
      tabButton.setLeadingImage(selectedImage, for: .selected)
      tabButton.setLeadingImage(disabledImage, for: .disabled)
    case .trailing:
      tabButton.setTrailingImage(normalImage, for: .normal)
      tabButton.setTrailingImage(selectedImage, for: .selected)
      tabButton.setTrailingImage(disabledImage, for: .disabled)
    }
  }

  private func interpolate(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
    var fr: CGFloat = 0
    var fg: CGFloat = 0
    var fb: CGFloat = 0
    var fa: CGFloat = 0
    var tr: CGFloat = 0
    var tg: CGFloat = 0
    var tb: CGFloat = 0
    var ta: CGFloat = 0
    guard from.getRed(&fr, green: &fg, blue: &fb, alpha: &fa),
          to.getRed(&tr, green: &tg, blue: &tb, alpha: &ta) else {
      return progress < 0.5 ? from : to
    }
    let p = max(0, min(1, progress))
    return UIColor(
      red: fr + (tr - fr) * p,
      green: fg + (tg - fg) * p,
      blue: fb + (tb - fb) * p,
      alpha: fa + (ta - fa) * p
    )
  }
}

