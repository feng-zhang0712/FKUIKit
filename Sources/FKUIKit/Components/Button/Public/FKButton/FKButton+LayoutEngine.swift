import UIKit

extension FKButton {
  // MARK: - Internal layout engine
  
  func applyAxis() {
    switch axis {
    case .horizontal:
      stackView.axis = .horizontal
    case .vertical:
      stackView.axis = .vertical
    }
    applyContentAlignmentLayout()
  }

  /// Maps inherited `UIControl` alignment into `contentContainerView` constraints and `UIStackView` distribution/alignment.
  func applyContentAlignmentLayout() {
    guard stackView.superview === contentContainerView else { return }

    NSLayoutConstraint.deactivate(contentAlignmentConstraints)
    contentAlignmentConstraints.removeAll()

    let h = super.contentHorizontalAlignment
    let v = super.contentVerticalAlignment
    let c = contentContainerView

    applyStackViewMetricsForContentAlignment(horizontal: h, vertical: v)

    var next: [NSLayoutConstraint] = []

    switch h {
    case .fill:
      next += [
        stackView.leadingAnchor.constraint(equalTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      ]
    case .leading, .left:
      next += [
        stackView.leadingAnchor.constraint(equalTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(lessThanOrEqualTo: c.trailingAnchor),
      ]
    case .trailing, .right:
      next += [
        stackView.leadingAnchor.constraint(greaterThanOrEqualTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      ]
    case .center:
      next += [
        stackView.centerXAnchor.constraint(equalTo: c.centerXAnchor),
        stackView.leadingAnchor.constraint(greaterThanOrEqualTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(lessThanOrEqualTo: c.trailingAnchor),
      ]
    @unknown default:
      next += [
        stackView.leadingAnchor.constraint(equalTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      ]
    }

    switch v {
    case .fill:
      next += [
        stackView.topAnchor.constraint(equalTo: c.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: c.bottomAnchor),
      ]
    case .top:
      next += [
        stackView.topAnchor.constraint(equalTo: c.topAnchor),
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: c.bottomAnchor),
      ]
    case .bottom:
      next += [
        stackView.topAnchor.constraint(greaterThanOrEqualTo: c.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: c.bottomAnchor),
      ]
    case .center:
      next += [
        stackView.centerYAnchor.constraint(equalTo: c.centerYAnchor),
        stackView.topAnchor.constraint(greaterThanOrEqualTo: c.topAnchor),
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: c.bottomAnchor),
      ]
    @unknown default:
      next += [
        stackView.topAnchor.constraint(equalTo: c.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: c.bottomAnchor),
      ]
    }

    contentAlignmentConstraints = next
    NSLayoutConstraint.activate(next)
    invalidateIntrinsicContentSize()
  }

  func applyStackViewMetricsForContentAlignment(
    horizontal h: UIControl.ContentHorizontalAlignment,
    vertical v: UIControl.ContentVerticalAlignment
  ) {
    switch axis {
    case .horizontal:
      switch h {
      case .center:
        stackView.distribution = .equalCentering
      default:
        stackView.distribution = .fill
      }
      stackView.alignment = stackCrossAxisAlignmentForHorizontalStack(vertical: v)
    case .vertical:
      switch v {
      case .center:
        stackView.distribution = .equalCentering
      default:
        stackView.distribution = .fill
      }
      stackView.alignment = stackCrossAxisAlignmentForVerticalStack(horizontal: h)
    }
  }

  func stackCrossAxisAlignmentForHorizontalStack(vertical v: UIControl.ContentVerticalAlignment) -> UIStackView.Alignment {
    switch v {
    case .top:
      return .top
    case .bottom:
      return .bottom
    case .center:
      return .center
    case .fill:
      return .fill
    @unknown default:
      return .center
    }
  }

  func stackCrossAxisAlignmentForVerticalStack(horizontal h: UIControl.ContentHorizontalAlignment) -> UIStackView.Alignment {
    switch h {
    case .leading, .left:
      return .leading
    case .trailing, .right:
      return .trailing
    case .center:
      return .center
    case .fill:
      return .fill
    @unknown default:
      return .center
    }
  }

  func requestVisualRefresh(rebuildContentLayout: Bool = false) {
    if rebuildContentLayout {
      needsContentLayoutRefresh = true
    }
    if batchUpdateDepth > 0 {
      needsVisualRefresh = true
      return
    }
    flushPendingRefresh()
  }

  func flushPendingRefresh() {
    if needsContentLayoutRefresh {
      applyContentLayout()
      needsContentLayoutRefresh = false
    }
    applyTextForCurrentState()
    applyImagesForCurrentState()
    applyCustomContentForCurrentState()
    applyAppearanceForCurrentState()
    applyAccessibilityForCurrentState()
  }
  
  // MARK: - Title & subtitle lifecycle (lazy creation / cleanup)

  func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  func titleLabelIfNeeded() -> UILabel {
    if let existing = titleLabel { return existing }
    let label = makeTitleLabel()
    titleLabel = label
    return label
  }

  func releaseTitleLabel() {
    guard let label = titleLabel else { return }
    // Clear the subtitle first to avoid leaving behind internal constraints.
    releaseSubtitleLabel()
    titleContainerView?.removeFromSuperview()
    titleContainerView = nil
    titleLabelTopConstraint = nil
    titleLabelLeadingConstraint = nil
    titleLabelTrailingConstraint = nil
    titleLabelBottomConstraintToContainer = nil
    subtitleTopConstraint = nil
    subtitleLeadingConstraint = nil
    subtitleTrailingConstraint = nil
    subtitleBottomConstraint = nil
    label.removeFromSuperview()
    label.text = nil
    label.attributedText = nil
    titleLabel = nil
  }
  
  func titleContainerViewIfNeeded() -> UIView {
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
    let bottom = label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    titleLabelTopConstraint = top
    titleLabelLeadingConstraint = leading
    titleLabelTrailingConstraint = trailing
    titleLabelBottomConstraintToContainer = bottom
    NSLayoutConstraint.activate([top, leading, trailing, bottom])
    return container
  }
  
  func makeImageView() -> UIImageView {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFit
    imgView.setContentHuggingPriority(.required, for: .vertical)
    imgView.setContentHuggingPriority(.required, for: .horizontal)
    return imgView
  }

  func makeSubtitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  func subtitleLabelIfNeeded() -> UILabel {
    if let existing = subtitleLabel { return existing }
    let label = makeSubtitleLabel()
    subtitleLabel = label
    
    let container = titleContainerViewIfNeeded()
    if label.superview !== container {
      container.addSubview(label)
    }
    label.translatesAutoresizingMaskIntoConstraints = false
    
    // When the subtitle is added, the title's bottom is no longer pinned directly to the container;
    // it is connected through the subtitle.
    titleLabelBottomConstraintToContainer?.isActive = false
    
    let leading = label.leadingAnchor.constraint(equalTo: container.leadingAnchor)
    let trailing = label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    let top = label.topAnchor.constraint(equalTo: titleLabelIfNeeded().bottomAnchor)
    let bottom = label.bottomAnchor.constraint(equalTo: container.bottomAnchor)

    subtitleTopConstraint = top
    subtitleLeadingConstraint = leading
    subtitleTrailingConstraint = trailing
    subtitleBottomConstraint = bottom

    NSLayoutConstraint.activate([top, leading, trailing, bottom])
    return label
  }

  func releaseSubtitleLabel() {
    guard let label = subtitleLabel else { return }
    subtitleTopConstraint?.isActive = false
    subtitleLeadingConstraint?.isActive = false
    subtitleTrailingConstraint?.isActive = false
    subtitleBottomConstraint?.isActive = false
    subtitleTopConstraint = nil
    subtitleLeadingConstraint = nil
    subtitleTrailingConstraint = nil
    subtitleBottomConstraint = nil
    
    label.removeFromSuperview()
    label.text = nil
    label.attributedText = nil
    subtitleLabel = nil
    
    // After the subtitle is released, re-enable the title as the container's bottom anchor.
    titleLabelBottomConstraintToContainer?.isActive = true
  }

  /// Update constraints inside the title container based on the resolved `LabelAttributes.contentInsets`,
  /// including spacing between title and subtitle (`title.bottom + subtitle.top`).
  func updateTitleContainerLayoutConstraints() {
    guard let container = titleContainerView,
          let titleL = titleLabel,
          titleL.superview === container
    else { return }

    let titleText = resolveTitleElement()
    let ti = titleText.contentInsets
    titleLabelTopConstraint?.constant = ti.top
    titleLabelLeadingConstraint?.constant = ti.leading
    titleLabelTrailingConstraint?.constant = -ti.trailing

    if let subtitleL = subtitleLabel,
       subtitleL.superview === container,
       let subText = resolveSubtitleElement(),
       subtitleHasRenderableContent(subText) {
      let si = subText.contentInsets
      titleLabelBottomConstraintToContainer?.isActive = false
      subtitleTopConstraint?.constant = ti.bottom + si.top
      subtitleLeadingConstraint?.constant = si.leading
      subtitleTrailingConstraint?.constant = -si.trailing
      subtitleBottomConstraint?.constant = -si.bottom
    } else {
      titleLabelBottomConstraintToContainer?.isActive = true
      titleLabelBottomConstraintToContainer?.constant = -ti.bottom
    }

    invalidateIntrinsicContentSize()
  }

  func imageViewIfNeeded(for slot: ImageSlot) -> UIImageView {
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

  func clearImageSlot(_ slot: ImageSlot) {
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

  func releaseAllImageSlots() {
    clearImageSlot(.center)
    clearImageSlot(.leading)
    clearImageSlot(.trailing)
  }

  func customContentHostIfNeeded() -> FKButtonCustomContentHostView {
    if let existing = customContentHost { return existing }
    let host = FKButtonCustomContentHostView()
    host.isUserInteractionEnabled = false
    host.backgroundColor = .clear
    customContentHost = host
    return host
  }

  func releaseCustomContentHost() {
    embeddedCustomContentView?.removeFromSuperview()
    embeddedCustomContentView = nil
    customContentHost?.subviews.forEach { $0.removeFromSuperview() }
    customContentHost?.removeFromSuperview()
    customContentHost = nil
  }
}
