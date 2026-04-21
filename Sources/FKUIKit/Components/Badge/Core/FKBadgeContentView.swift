import UIKit

/// Internal view that draws either a circular dot or a padded label with pill corners.
@MainActor
final class FKBadgeContentView: UIView {
  /// Rendering mode used by the content view.
  enum Mode: Equatable {
    /// Dot-only badge.
    case dot
    /// Text/number badge.
    case text(String)
  }

  // Single label reused for text/number rendering.
  private let label = UILabel()
  // Constraints that depend on `mode` and configuration sizing options.
  private var sizingConstraints: [NSLayoutConstraint] = []

  /// Visual configuration for current badge rendering.
  var configuration = FKBadgeConfiguration() {
    didSet {
      applyConfiguration()
      rebuildMode()
    }
  }

  /// Current content mode.
  var mode: Mode = .dot {
    didSet { if oldValue != mode { rebuildMode() } }
  }

  /// Initializes with frame.
  ///
  /// - Parameter frame: Initial frame. Auto Layout usually overrides this value.
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  /// Initializes from Interface Builder.
  ///
  /// - Parameter coder: Decoder used by nib/storyboard loading.
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  // Creates subviews and static view-level behavior.
  private func setup() {
    translatesAutoresizingMaskIntoConstraints = false
    isUserInteractionEnabled = false
    clipsToBounds = true
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.adjustsFontForContentSizeCategory = false
    label.numberOfLines = 1
    label.lineBreakMode = .byClipping
    addSubview(label)

    rebuildMode()
    applyConfiguration()
  }

  // Applies colors, typography, kerning, and border styles.
  private func applyConfiguration() {
    backgroundColor = configuration.backgroundColor
    label.textColor = configuration.titleColor
    label.font = configuration.font
    if let text = label.text, !text.isEmpty {
      label.attributedText = NSAttributedString(
        string: text,
        attributes: [.kern: configuration.textKerning]
      )
    }
    layer.borderWidth = configuration.borderWidth
    layer.borderColor = configuration.borderColor.cgColor
  }

  // Rebuilds size/content constraints whenever mode or configuration changes.
  private func rebuildMode() {
    NSLayoutConstraint.deactivate(sizingConstraints)
    sizingConstraints.removeAll()

    switch mode {
    case .dot:
      label.isHidden = true
      label.text = nil
      let d = configuration.dotDiameter
      sizingConstraints = [
        widthAnchor.constraint(equalToConstant: d),
        heightAnchor.constraint(equalToConstant: d),
      ]

    case .text(let text):
      label.isHidden = false
      label.attributedText = NSAttributedString(
        string: text,
        attributes: [.kern: configuration.textKerning]
      )
      let numericStyle = text.allSatisfy { $0.isNumber || $0 == "+" }
      // Keep numeric glyph order LTR so "99+" stays visually stable in RTL layouts.
      label.semanticContentAttribute = numericStyle ? .forceLeftToRight : .unspecified
      let hp = configuration.horizontalPadding
      let vp = configuration.verticalPadding
      let minW = configuration.minimumContentWidth

      var constraints: [NSLayoutConstraint] = [
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hp),
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -hp),
        label.topAnchor.constraint(equalTo: topAnchor, constant: vp),
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vp),
      ]

      if let minW {
        let w = widthAnchor.constraint(greaterThanOrEqualToConstant: minW)
        w.priority = .required
        constraints.append(w)
      }

      // Enforce pill floor so text badges never collapse narrower than their height.
      let pillFloor = widthAnchor.constraint(greaterThanOrEqualTo: heightAnchor)
      pillFloor.priority = .required
      constraints.append(pillFloor)

      sizingConstraints = constraints
    }

    NSLayoutConstraint.activate(sizingConstraints)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    switch mode {
    case .dot:
      // Dot mode is always circular.
      layer.cornerRadius = bounds.height * 0.5
    case .text:
      let h = bounds.height
      guard h > 0 else { return }
      // Text mode supports explicit corner radius override, otherwise uses pill radius.
      if let r = configuration.textCornerRadius {
        layer.cornerRadius = r
      } else {
        layer.cornerRadius = h * 0.5
      }
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Re-apply CGColor to keep dynamic colors correct across appearance changes.
    layer.borderColor = configuration.borderColor.cgColor
  }

  /// Resets transient visual state before reuse/removal.
  func prepareForReuse() {
    layer.removeAllAnimations()
    transform = .identity
    alpha = 1
  }
}
