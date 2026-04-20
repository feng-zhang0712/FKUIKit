//
// FKExpandableTextButton.swift
//
// Internal button view used by FKExpandableText.
//

import UIKit

/// Internal action button used by `FKExpandableText`.
///
/// The button supports text-only and icon+text presentation according to
/// `FKExpandableTextButtonStyle`.
final class FKExpandableTextButton: UIButton {
  /// Last applied style snapshot for state-driven updates.
  private var style = FKExpandableTextButtonStyle()

  /// Creates button from frame-based initializer.
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  /// Creates button from Interface Builder.
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  /// Performs one-time control setup.
  ///
  /// This method keeps visual behavior consistent across iOS versions.
  private func setup() {
    adjustsImageWhenHighlighted = false
    showsTouchWhenHighlighted = false
    contentHorizontalAlignment = .trailing
    titleLabel?.lineBreakMode = .byTruncatingTail
    if #available(iOS 15.0, *) {
      var config = UIButton.Configuration.plain()
      config.contentInsets = .zero
      configuration = config
    }
  }

  /// Applies style and expanded/collapsed title state to the button.
  ///
  /// - Parameters:
  ///   - style: Button style model.
  ///   - state: Current text display state used to choose title.
  func apply(style: FKExpandableTextButtonStyle, state: FKExpandableTextDisplayState) {
    self.style = style
    setTitle(state == .expanded ? style.collapseTitle : style.expandTitle, for: .normal)
    setTitleColor(style.titleColor, for: .normal)
    setTitleColor(style.highlightedTitleColor, for: .highlighted)
    titleLabel?.font = style.font
    contentEdgeInsets = style.contentInsets

    // Configure icon+title layout when icon is provided.
    if let image = style.image {
      let rendered = image.withRenderingMode(.alwaysTemplate)
      setImage(rendered, for: .normal)
      tintColor = style.imageTintColor ?? style.titleColor
      semanticContentAttribute = .forceRightToLeft
      imageEdgeInsets = UIEdgeInsets(top: 0, left: style.imageTitleSpacing, bottom: 0, right: -style.imageTitleSpacing)
      titleEdgeInsets = UIEdgeInsets(top: 0, left: -style.imageTitleSpacing, bottom: 0, right: style.imageTitleSpacing)
    } else {
      // Reset icon-related insets for title-only mode.
      setImage(nil, for: .normal)
      imageEdgeInsets = .zero
      titleEdgeInsets = .zero
    }
  }
}
