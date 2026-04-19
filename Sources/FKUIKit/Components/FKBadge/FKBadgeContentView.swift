//
// FKBadgeContentView.swift
//

import UIKit

/// Internal view that draws either a circular dot or a padded label with pill corners.
@MainActor
final class FKBadgeContentView: UIView {
  enum Mode: Equatable {
    case dot
    case text(String)
  }

  private let label = UILabel()
  private var sizingConstraints: [NSLayoutConstraint] = []

  var configuration = FKBadgeConfiguration() {
    didSet {
      applyConfiguration()
      rebuildMode()
    }
  }

  var mode: Mode = .dot {
    didSet { if oldValue != mode { rebuildMode() } }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

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

  private func applyConfiguration() {
    backgroundColor = configuration.backgroundColor
    label.textColor = configuration.titleColor
    label.font = configuration.font
    layer.borderWidth = configuration.borderWidth
    layer.borderColor = configuration.borderColor.cgColor
  }

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
      label.text = text
      let numericStyle = text.allSatisfy { $0.isNumber || $0 == "+" }
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
      layer.cornerRadius = bounds.height * 0.5
    case .text:
      let h = bounds.height
      guard h > 0 else { return }
      if let r = configuration.textCornerRadius {
        layer.cornerRadius = r
      } else {
        layer.cornerRadius = h * 0.5
      }
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    layer.borderColor = configuration.borderColor.cgColor
  }

  func prepareForReuse() {
    layer.removeAllAnimations()
    transform = .identity
    alpha = 1
  }
}
