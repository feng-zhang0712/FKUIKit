//
// FKExpandableTextBasicExampleViewController.swift
//
// Basic feature playground for FKExpandableText.
//

import FKUIKit
import UIKit

/// Demonstrates the complete core usage of `FKExpandableText` in a single screen.
///
/// Covered scenarios:
/// - Basic long text expand/collapse (3 lines)
/// - Attributed text with custom style
/// - Custom button text and color
/// - Custom text font/color/line spacing/alignment
/// - Auto hide button for short text
/// - Smooth animation
/// - Global style configuration
/// - State callback
/// - Manual expand/collapse control
/// - Disable interaction and force fixed state
final class FKExpandableTextBasicExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  private let basicExpandable = FKExpandableText()
  private let attributedExpandable = FKExpandableText()
  private let shortTextExpandable = FKExpandableText()
  private let fixedStateExpandable = FKExpandableText()
  private let callbackLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Expandable Basic"
    view.backgroundColor = .systemBackground

    configureGlobalStyle()
    setupLayout()
    setupExamples()
    setupNavigationItems()
  }

  // MARK: - Setup

  private func configureGlobalStyle() {
    // Apply one baseline style globally, then override per instance.
    FKExpandableText.defaultConfiguration = .build {
      $0.behavior.collapsedNumberOfLines = 3
      $0.layoutStyle.animationDuration = 0.28
      $0.layoutStyle.buttonPosition = .bottomTrailing
      $0.buttonStyle.expandTitle = "Read More"
      $0.buttonStyle.collapseTitle = "Collapse"
      $0.buttonStyle.titleColor = .systemBlue
      $0.buttonStyle.highlightedTitleColor = .systemGray
      $0.textStyle.font = .systemFont(ofSize: 16)
      $0.textStyle.lineSpacing = 6
    }
  }

  private func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
    ])
  }

  private func setupExamples() {
    stackView.addArrangedSubview(makeHeader("1) Basic Long Text Expand/Collapse (3 lines)"))
    setupBasicExpandable()
    stackView.addArrangedSubview(basicExpandable)

    stackView.addArrangedSubview(makeHeader("2) Attributed String + Custom Style"))
    setupAttributedExpandable()
    stackView.addArrangedSubview(attributedExpandable)

    stackView.addArrangedSubview(makeHeader("3) Auto Hide Button for Short Text"))
    setupShortTextExpandable()
    stackView.addArrangedSubview(shortTextExpandable)

    stackView.addArrangedSubview(makeHeader("4) Disable Interaction with Fixed State"))
    setupFixedStateExpandable()
    stackView.addArrangedSubview(fixedStateExpandable)

    stackView.addArrangedSubview(makeHeader("State Change Callback"))
    callbackLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    callbackLabel.textColor = .secondaryLabel
    callbackLabel.numberOfLines = 0
    callbackLabel.text = "Waiting for state change..."
    stackView.addArrangedSubview(callbackLabel)
  }

  private func setupBasicExpandable() {
    basicExpandable.configure {
      $0.behavior.collapsedNumberOfLines = 3
      $0.behavior.triggerMode = .all
      $0.layoutStyle.contentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
      $0.layoutStyle.textButtonSpacing = 8
      $0.buttonStyle.expandTitle = "Read More"
      $0.buttonStyle.collapseTitle = "Show Less"
      $0.buttonStyle.titleColor = .systemIndigo
      $0.buttonStyle.highlightedTitleColor = .systemPurple
      $0.buttonStyle.image = UIImage(systemName: "chevron.down")
      $0.buttonStyle.imageTintColor = .systemIndigo
    }
    basicExpandable.layer.cornerRadius = 12
    basicExpandable.layer.borderWidth = 1
    basicExpandable.layer.borderColor = UIColor.systemGray4.cgColor
    basicExpandable.setText(Self.longText, stateIdentifier: "basic_long_text")

    // Update external callback panel when state changes.
    basicExpandable.onStateChange = { [weak self] context in
      self?.callbackLabel.text = "basic_long_text -> state: \(context.state), truncated: \(context.isTruncated)"
    }
  }

  private func setupAttributedExpandable() {
    attributedExpandable.configure {
      $0.behavior.collapsedNumberOfLines = 4
      $0.layoutStyle.buttonPosition = .tailFollow
      $0.buttonStyle.expandTitle = "See Details"
      $0.buttonStyle.collapseTitle = "Fold"
      $0.buttonStyle.titleColor = .systemTeal
      $0.textStyle.font = .systemFont(ofSize: 15)
      $0.textStyle.color = .darkText
      $0.textStyle.lineSpacing = 7
      $0.textStyle.alignment = .justified
    }
    attributedExpandable.layer.cornerRadius = 12
    attributedExpandable.layer.borderWidth = 1
    attributedExpandable.layer.borderColor = UIColor.systemGray4.cgColor
    attributedExpandable.setAttributedText(Self.makeAttributedLongText(), stateIdentifier: "attributed_text")
  }

  private func setupShortTextExpandable() {
    shortTextExpandable.configure {
      $0.behavior.collapsedNumberOfLines = 3
      $0.textStyle.alignment = .center
      $0.textStyle.color = .systemGreen
      $0.buttonStyle.expandTitle = "Should Hide"
      $0.buttonStyle.collapseTitle = "Should Hide"
    }
    shortTextExpandable.layer.cornerRadius = 12
    shortTextExpandable.layer.borderWidth = 1
    shortTextExpandable.layer.borderColor = UIColor.systemGray4.cgColor
    shortTextExpandable.setText("Short content. No expand button should be shown.", stateIdentifier: "short_text")
  }

  private func setupFixedStateExpandable() {
    fixedStateExpandable.configure {
      // This configuration forces expanded display and disables interaction.
      $0.behavior.fixedState = .expanded
      $0.behavior.isInteractionEnabled = false
      $0.behavior.triggerMode = .all
      $0.buttonStyle.expandTitle = "Disabled"
      $0.buttonStyle.collapseTitle = "Disabled"
      $0.textStyle.color = .systemOrange
      $0.layoutStyle.contentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
    fixedStateExpandable.layer.cornerRadius = 12
    fixedStateExpandable.layer.borderWidth = 1
    fixedStateExpandable.layer.borderColor = UIColor.systemGray4.cgColor
    fixedStateExpandable.setText(Self.longText, stateIdentifier: "fixed_state")
  }

  private func setupNavigationItems() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        title: "Collapse",
        style: .plain,
        target: self,
        action: #selector(collapseAll)
      ),
      UIBarButtonItem(
        title: "Expand",
        style: .plain,
        target: self,
        action: #selector(expandAll)
      )
    ]
  }

  // MARK: - Actions

  @objc
  private func expandAll() {
    // Manual control API with animation.
    [basicExpandable, attributedExpandable, shortTextExpandable].forEach {
      $0.setExpanded(true, animated: true)
    }
  }

  @objc
  private func collapseAll() {
    [basicExpandable, attributedExpandable, shortTextExpandable].forEach {
      $0.setExpanded(false, animated: true)
    }
  }

  // MARK: - UI Factory

  private func makeHeader(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .semibold)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}

private extension FKExpandableTextBasicExampleViewController {
  static let longText = """
  FKExpandableText is designed for long content in social feeds, comments, and article previews.
  It supports smooth expand/collapse animations, configurable line limits, rich text, and reusable list performance optimization.
  You can customize text style, button style, layout spacing, and interaction mode with a concise API.
  """

  static func makeAttributedLongText() -> NSAttributedString {
    let text = NSMutableAttributedString(
      string: """
      Attributed text is fully supported. You can still apply component-level style for alignment and spacing.
      This paragraph highlights key words with custom color and weight while keeping expand/collapse behavior consistent.
      """
    )
    text.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 0, length: 15))
    text.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: NSRange(location: 0, length: 15))
    text.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 54, length: 10))
    return text
  }
}
