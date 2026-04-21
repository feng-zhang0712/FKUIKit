//
// FKSwipeActionButtonView.swift
//
// Render and interaction layer for one swipe action item.
//

import UIKit

@MainActor
final class FKSwipeActionButtonView: UIControl {
  /// Label for optional action title.
  private let titleLabelView = UILabel()
  /// Image view for optional action icon.
  private let imageView = UIImageView()
  /// Horizontal content stack containing icon and title.
  private let stackView = UIStackView()

  /// Current rendered action item.
  private(set) var item: FKSwipeActionItem

  /// Tap relay callback assigned by controller.
  var tapHandler: (() -> Void)?

  /// Creates one reusable action button view.
  ///
  /// - Parameter item: Action item used for visual and interaction state.
  init(item: FKSwipeActionItem) {
    self.item = item
    super.init(frame: .zero)
    setupViews()
    apply(item: item)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isHighlighted: Bool {
    didSet {
      // Toggle normal/highlight background colors for immediate touch feedback.
      backgroundColor = isHighlighted ? item.style.highlightedBackgroundColor : item.style.backgroundColor
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Update corner style during layout to follow runtime bounds changes.
    layer.cornerRadius = item.style.cornerRadius
    layer.masksToBounds = item.style.cornerRadius > 0
  }

  /// Applies item content and style to current button view.
  ///
  /// - Parameter item: New item model to render.
  func apply(item: FKSwipeActionItem) {
    self.item = item
    isEnabled = item.isEnabled
    accessibilityIdentifier = item.identifier
    backgroundColor = item.style.backgroundColor

    // Configure title branch.
    titleLabelView.text = item.title
    titleLabelView.font = item.style.titleFont
    titleLabelView.textColor = item.style.titleColor
    titleLabelView.isHidden = (item.title?.isEmpty ?? true)

    // Configure icon branch.
    if let image = item.image {
      if let tint = item.style.imageTintColor {
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = tint
      } else {
        imageView.image = image
        imageView.tintColor = nil
      }
      imageView.isHidden = false
    } else {
      imageView.image = nil
      imageView.isHidden = true
    }

    // Invalidate intrinsic size after content/style updates.
    stackView.spacing = item.style.imageTitleSpacing
    setNeedsLayout()
    invalidateIntrinsicContentSize()
  }

  override var intrinsicContentSize: CGSize {
    // Respect fixed width first to support deterministic button sizing.
    if let fixedWidth = item.style.fixedWidth {
      return CGSize(width: max(44, fixedWidth), height: UIView.noIntrinsicMetric)
    }
    // Otherwise compute adaptive width from icon/title/insets.
    let titleWidth = titleLabelView.isHidden ? 0 : titleLabelView.intrinsicContentSize.width
    let iconWidth = imageView.isHidden ? 0 : (item.style.imageSize?.width ?? imageView.intrinsicContentSize.width)
    let hasSpacing = (!titleLabelView.isHidden && !imageView.isHidden) ? item.style.imageTitleSpacing : 0
    let width = item.style.contentInsets.left + titleWidth + iconWidth + hasSpacing + item.style.contentInsets.right
    return CGSize(width: max(item.style.minimumWidth, width), height: UIView.noIntrinsicMetric)
  }

  /// Builds static subviews and constraints once at initialization.
  private func setupViews() {
    addTarget(self, action: #selector(didTap), for: .touchUpInside)

    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false

    // Keep content compact when width is constrained.
    imageView.contentMode = .scaleAspectFit
    imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    titleLabelView.setContentCompressionResistancePriority(.required, for: .horizontal)

    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(titleLabelView)
    addSubview(stackView)

    // Anchor stack to configurable content insets.
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: item.style.contentInsets.left),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -item.style.contentInsets.right),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: item.style.contentInsets.top),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -item.style.contentInsets.bottom)
    ])
  }

  /// Emits tap event to external handler.
  @objc private func didTap() {
    tapHandler?()
  }
}
