import UIKit

extension FKButton {
  // MARK: - Text rendering

  func applyTextForCurrentState() {
    switch content.kind {
    case .textOnly, .textAndImage:
      let title = resolveTitleElement()
      applyTitle(title)
      applySubtitleForCurrentState()
      updateTitleContainerLayoutConstraints()
    case .imageOnly:
      releaseTitleLabel()
      releaseSubtitleLabel()
    case .custom:
      releaseTitleLabel()
      releaseSubtitleLabel()
    }
  }

  // MARK: - Element resolution & rendering (stateful lookups)

  func resolveSubtitleElement() -> LabelAttributes? {
    resolveFromStateMap(subtitleByState)
  }

  func subtitleHasRenderableContent(_ subtitle: LabelAttributes) -> Bool {
    if subtitle.attributedText != nil { return true }
    if let text = subtitle.text { return !text.isEmpty }
    return false
  }

  func applySubtitleForCurrentState() {
    guard let subtitle = resolveSubtitleElement(), subtitleHasRenderableContent(subtitle) else {
      releaseSubtitleLabel()
      return
    }
    applySubtitle(subtitle)
  }
  
  // MARK: - Image rendering

  func applyImagesForCurrentState() {
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

  func resolveCustomContent() -> CustomContent? {
    resolveFromStateMap(customContentByState)
  }

  // MARK: - Custom content rendering

  func applyCustomContentForCurrentState() {
    guard case .custom = content.kind else {
      releaseCustomContentHost()
      return
    }

    let element = resolveCustomContent()
    let newView = element?.view

    // Only a single "pure custom" content slot for now.
    // `spacingToAdjacentContent` is reserved for future mixed text/image layouts.
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

  // MARK: - State resolution (supports combined states)

  var stateResolutionOrder: [UIControl.State] {
    if let provider = stateResolutionProvider {
      return provider(isEnabled, isSelected, isHighlighted)
    }
    if !isEnabled {
      // Support explicit combined registrations like `.disabled.union(.selected)`.
      if isSelected { return [.disabled.union(.selected), .disabled, .normal] }
      return [.disabled, .normal]
    }
    // Support `.selected + .highlighted` as a first-class candidate.
    if isHighlighted, isSelected { return [.highlighted.union(.selected), .highlighted, .selected, .normal] }
    if isHighlighted { return [.highlighted, .normal] }
    if isSelected { return [.selected, .normal] }
    return [.normal]
  }

  func resolveFromStateMap<T>(_ map: StatefulValues<T>) -> T? {
    for state in stateResolutionOrder {
      if let value = map[Self.makeStateKey(state)] {
        return value
      }
    }
    return nil
  }

  func resolveAppearance() -> Appearance {
    resolveFromStateMap(appearanceByState) ?? .default
  }

  func resolveTitleElement() -> LabelAttributes {
    resolveFromStateMap(titleByState) ?? .default
  }

  func resolveImageElement(for slot: ImageSlot) -> ImageAttributes? {
    guard let map = imagesBySlotAndState[slot] else { return nil }
    return resolveFromStateMap(map)
  }

  func storeImage(_ image: ImageAttributes?, slot: ImageSlot, for state: UIControl.State) {
    let key = Self.makeStateKey(state)
    if var map = imagesBySlotAndState[slot] {
      if let image {
        map[key] = image
      } else {
        map.removeValue(forKey: key)
      }
      imagesBySlotAndState[slot] = map
    } else {
      imagesBySlotAndState[slot] = image.map { [key: $0] } ?? [:]
    }
  }

  // MARK: - UILabel application

  func applyTitle(_ title: LabelAttributes) {
    let label = titleLabelIfNeeded()
    label.textAlignment = title.alignment
    label.numberOfLines = title.numberOfLines
    label.lineBreakMode = title.lineBreakMode
    label.adjustsFontForContentSizeCategory = title.adjustsFontForContentSizeCategory
    label.adjustsFontSizeToFitWidth = title.adjustsFontSizeToFitWidth
    label.minimumScaleFactor = title.minimumScaleFactor
    label.allowsDefaultTighteningForTruncation = title.allowsDefaultTighteningForTruncation
    label.shadowColor = title.shadowColor
    label.shadowOffset = title.shadowOffset

    if let attributed = title.attributedText {
      label.attributedText = attributed
      return
    }

    let text = transformedText(from: title.text ?? "", by: title.textTransform)

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
      .font: scaledFont(for: title),
      .foregroundColor: title.color,
      .kern: title.kerning,
      .paragraphStyle: paragraph,
    ]
    label.attributedText = NSAttributedString(string: text, attributes: attributes)
  }

  func applySubtitle(_ subtitle: LabelAttributes) {
    let label = subtitleLabelIfNeeded()
    label.textAlignment = subtitle.alignment
    label.numberOfLines = subtitle.numberOfLines
    label.lineBreakMode = subtitle.lineBreakMode
    label.adjustsFontForContentSizeCategory = subtitle.adjustsFontForContentSizeCategory
    label.adjustsFontSizeToFitWidth = subtitle.adjustsFontSizeToFitWidth
    label.minimumScaleFactor = subtitle.minimumScaleFactor
    label.allowsDefaultTighteningForTruncation = subtitle.allowsDefaultTighteningForTruncation
    label.shadowColor = subtitle.shadowColor
    label.shadowOffset = subtitle.shadowOffset

    if let attributed = subtitle.attributedText {
      label.attributedText = attributed
      return
    }

    let text = transformedText(from: subtitle.text ?? "", by: subtitle.textTransform)

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
      .font: scaledFont(for: subtitle),
      .foregroundColor: subtitle.color,
      .kern: subtitle.kerning,
      .paragraphStyle: paragraph,
    ]
    label.attributedText = NSAttributedString(string: text, attributes: attributes)
  }

  func scaledFont(for configuration: LabelAttributes) -> UIFont {
    guard configuration.adjustsFontForContentSizeCategory else { return configuration.font }
    if let style = configuration.textStyle {
      return UIFontMetrics(forTextStyle: style).scaledFont(for: configuration.font, compatibleWith: traitCollection)
    }
    return UIFontMetrics.default.scaledFont(for: configuration.font, compatibleWith: traitCollection)
  }

  // MARK: - UIImageView application

  func applyImage(_ element: ImageAttributes?, to imageView: UIImageView) {
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
    rendered = rendered.flatMap { paddedImage(from: $0, contentInsets: element.contentInsets) }

    imageView.image = rendered
    imageView.tintColor = element.tintColor
    imageView.contentMode = resolvedImageContentMode(for: element)
    imageView.semanticContentAttribute = element.flipsForRightToLeftLayoutDirection ? .unspecified : .forceLeftToRight
    imageView.accessibilityLabel = element.accessibilityLabel
    imageView.accessibilityHint = element.accessibilityHint
    imageView.accessibilityIdentifier = element.accessibilityIdentifier
    imageView.isAccessibilityElement = false
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

  func deactivateImageConstraints(for imageView: UIImageView) {
    let key = ObjectIdentifier(imageView)
    if let constraints = imageConstraints[key] {
      NSLayoutConstraint.deactivate(constraints)
      imageConstraints[key] = nil
    }
  }

  func transformedText(from text: String, by transform: LabelAttributes.TextTransform) -> String {
    switch transform {
    case .none:
      return text
    case .uppercase:
      return text.uppercased()
    case .lowercase:
      return text.lowercased()
    }
  }

  /// Enforces aspect-preserving content mode when requested by `ImageAttributes.preserveAspectRatio`.
  func resolvedImageContentMode(for element: ImageAttributes) -> UIView.ContentMode {
    guard element.preserveAspectRatio else { return element.contentMode }
    switch element.contentMode {
    case .scaleToFill:
      return .scaleAspectFit
    default:
      return element.contentMode
    }
  }

  // MARK: - Image padding (rendered cache)

  /// Applies directional insets by rendering into a padded bitmap.
  func paddedImage(from image: UIImage, contentInsets: NSDirectionalEdgeInsets) -> UIImage {
    guard contentInsets != .zero else { return image }
    let directional = effectiveDirectionalInsets(contentInsets)
    // `ObjectIdentifier(image).hashValue` is not guaranteed stable/unique across executions.
    // Use the object pointer address + insets + scale to reduce collision risk.
    let ptr = Unmanaged.passUnretained(image).toOpaque()
    let cacheKey = "\(ptr)-\(directional.top)-\(directional.left)-\(directional.bottom)-\(directional.right)-\(image.scale)" as NSString
    if let cached = Self.paddedImageCache.object(forKey: cacheKey) {
      return cached
    }
    let horizontal = directional.left + directional.right
    let vertical = directional.top + directional.bottom
    let size = CGSize(width: image.size.width + horizontal, height: image.size.height + vertical)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = image.scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let padded = renderer.image { _ in
      image.draw(at: CGPoint(x: directional.left, y: directional.top))
    }
    Self.paddedImageCache.setObject(padded, forKey: cacheKey)
    return padded
  }

  /// Resolves directional insets into physical edges under current layout direction.
  func effectiveDirectionalInsets(_ insets: NSDirectionalEdgeInsets) -> UIEdgeInsets {
    let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
    return UIEdgeInsets(
      top: max(0, insets.top),
      left: max(0, isRTL ? insets.trailing : insets.leading),
      bottom: max(0, insets.bottom),
      right: max(0, isRTL ? insets.leading : insets.trailing)
    )
  }
}
