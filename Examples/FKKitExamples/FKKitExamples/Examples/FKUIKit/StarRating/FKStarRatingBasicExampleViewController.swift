//
// FKStarRatingBasicExampleViewController.swift
//
// Complete feature playground for FKStarRating.
//

import FKUIKit
import UIKit

/// Demonstrates all core usage patterns of `FKStarRating`.
final class FKStarRatingBasicExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let callbackLabel = UILabel()

  private let fullEditableRating = FKStarRating()
  private let halfDisplayRating = FKStarRating()
  private let preciseContinuousRating = FKStarRating()
  private let readOnlyRating = FKStarRating()
  private let threeStarRating = FKStarRating()
  private let tenStarRating = FKStarRating()
  private let imageStyleRating = FKStarRating()
  private let switchModeRating = FKStarRating()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "StarRating Basic"
    view.backgroundColor = .systemBackground
    setupGlobalStyle()
    setupLayout()
    setupExamples()
    setupNavigationItems()
  }
}

private extension FKStarRatingBasicExampleViewController {
  // MARK: - Setup

  func setupGlobalStyle() {
    // Set global defaults once. Every new instance copies this baseline.
    FKStarRating.defaultConfiguration = .build {
      $0.mode = .half
      $0.starCount = 5
      $0.starSize = CGSize(width: 24, height: 24)
      $0.starSpacing = 8
      $0.minimumRating = 0
      $0.maximumRating = 5
      $0.renderMode = .color
      $0.selectedColor = .systemYellow
      $0.unselectedColor = .systemGray4
      $0.allowsContinuousPan = true
      $0.starStyle = FKStarRatingStarStyle(
        cornerRadius: 4,
        borderWidth: 0,
        borderColor: .clear,
        shadowColor: UIColor.black.withAlphaComponent(0.14),
        shadowOpacity: 0,
        shadowRadius: 0,
        shadowOffset: .zero
      )
    }
  }

  func setupLayout() {
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
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
    ])
  }

  func setupExamples() {
    addFullEditableExample()
    addHalfStarExample()
    addPreciseDecimalExample()
    addReadOnlyExample()
    addCustomCountExamples()
    addCustomSpacingAndTintExample()
    addImageStyleExample()
    addModeSwitchingExample()
    addCallbackPanel()
  }

  func setupNavigationItems() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Reset All", style: .plain, target: self, action: #selector(resetAllRatings)),
      UIBarButtonItem(title: "Set 4.5", style: .plain, target: self, action: #selector(setAllToFourPointFive)),
    ]
  }

  // MARK: - Feature Blocks

  func addFullEditableExample() {
    stackView.addArrangedSubview(makeHeader("1) Basic 5-star full rating (editable with tap gesture)"))
    fullEditableRating
      .withMode(.full)
      .withEditable(true)
      .withRange(min: 0, max: 5)
      .withColors(selected: .systemOrange, unselected: .systemGray4)
    fullEditableRating.setRating(3, notify: false)
    fullEditableRating.onRatingChanged = { [weak self] value in
      self?.callbackLabel.text = "Full editable changed: \(value)"
    }
    fullEditableRating.heightAnchor.constraint(equalToConstant: 28).isActive = true
    stackView.addArrangedSubview(fullEditableRating)
  }

  func addHalfStarExample() {
    stackView.addArrangedSubview(makeHeader("2) Half-star rating component (display & edit mode)"))

    // First one is display-only.
    halfDisplayRating
      .withMode(.half)
      .withEditable(false)
      .withColors(selected: .systemYellow, unselected: .systemGray4)
    halfDisplayRating.setRating(3.5, notify: false)
    halfDisplayRating.heightAnchor.constraint(equalToConstant: 28).isActive = true
    stackView.addArrangedSubview(halfDisplayRating)

    // Second one demonstrates editable half-star.
    let halfEditable = FKStarRating()
      .withMode(.half)
      .withEditable(true)
      .withColors(selected: .systemPink, unselected: .systemGray4)
    halfEditable.setRating(2.5, notify: false)
    halfEditable.onRatingCommit = { [weak self] value in
      self?.callbackLabel.text = "Half editable committed: \(value)"
    }
    halfEditable.heightAnchor.constraint(equalToConstant: 28).isActive = true
    stackView.addArrangedSubview(halfEditable)
  }

  func addPreciseDecimalExample() {
    stackView.addArrangedSubview(makeHeader("3) Precise decimal rating (continuous slide rating)"))
    preciseContinuousRating.configure {
      $0.mode = .precise(step: 0.1)
      $0.isEditable = true
      $0.allowsContinuousPan = true
      $0.selectedColor = .systemGreen
      $0.unselectedColor = .systemGray4
    }
    preciseContinuousRating.setRating(4.2, notify: false)
    preciseContinuousRating.onRatingChanged = { [weak self] value in
      self?.callbackLabel.text = String(format: "Precise changing: %.1f", value)
    }
    preciseContinuousRating.onRatingCommit = { [weak self] value in
      self?.callbackLabel.text = String(format: "Precise committed: %.1f", value)
    }
    preciseContinuousRating.heightAnchor.constraint(equalToConstant: 28).isActive = true
    stackView.addArrangedSubview(preciseContinuousRating)
  }

  func addReadOnlyExample() {
    stackView.addArrangedSubview(makeHeader("4) Read-only star rating (for score display only)"))
    readOnlyRating
      .withMode(.precise(step: 0.1))
      .withEditable(false)
      .withColors(selected: .systemBlue, unselected: .systemGray5)
    readOnlyRating.configure {
      $0.starStyle = FKStarRatingStarStyle(
        cornerRadius: 6,
        borderWidth: 1,
        borderColor: .systemGray5,
        shadowColor: UIColor.black.withAlphaComponent(0.2),
        shadowOpacity: 0.12,
        shadowRadius: 4,
        shadowOffset: CGSize(width: 0, height: 2)
      )
    }
    readOnlyRating.setRating(4.8, notify: false)
    readOnlyRating.heightAnchor.constraint(equalToConstant: 30).isActive = true
    stackView.addArrangedSubview(readOnlyRating)
  }

  func addCustomCountExamples() {
    stackView.addArrangedSubview(makeHeader("5) Custom star count (3 stars / 10 stars)"))

    threeStarRating
      .withMode(.half)
      .withStarCount(3)
      .withRange(min: 0, max: 3)
      .withEditable(true)
      .withColors(selected: .systemRed, unselected: .systemGray4)
    threeStarRating.setRating(2.5, notify: false)
    threeStarRating.heightAnchor.constraint(equalToConstant: 26).isActive = true
    stackView.addArrangedSubview(threeStarRating)

    tenStarRating.configure {
      $0.mode = .full
      $0.starCount = 10
      $0.minimumRating = 0
      $0.maximumRating = 10
      $0.starSize = CGSize(width: 18, height: 18)
      $0.starSpacing = 4
      $0.selectedColor = .systemTeal
      $0.unselectedColor = .systemGray4
      $0.isEditable = true
    }
    tenStarRating.setRating(7, notify: false)
    tenStarRating.heightAnchor.constraint(equalToConstant: 22).isActive = true
    stackView.addArrangedSubview(tenStarRating)
  }

  func addCustomSpacingAndTintExample() {
    stackView.addArrangedSubview(makeHeader("6) Custom star size, spacing, tint colors"))
    let customStyle = FKStarRating()
    customStyle.configure {
      $0.mode = .half
      $0.starCount = 5
      $0.starSize = CGSize(width: 30, height: 30)
      $0.starSpacing = 12
      $0.selectedColor = .systemPurple
      $0.unselectedColor = .systemGray3
      $0.starStyle = FKStarRatingStarStyle(
        cornerRadius: 8,
        borderWidth: 0.5,
        borderColor: .systemPurple.withAlphaComponent(0.3),
        shadowColor: UIColor.black.withAlphaComponent(0.2),
        shadowOpacity: 0.1,
        shadowRadius: 3,
        shadowOffset: CGSize(width: 0, height: 1)
      )
    }
    customStyle.setRating(4.5, notify: false)
    customStyle.heightAnchor.constraint(equalToConstant: 34).isActive = true
    stackView.addArrangedSubview(customStyle)
  }

  func addImageStyleExample() {
    stackView.addArrangedSubview(makeHeader("7) Custom image style (selected/unselected/half images)"))
    imageStyleRating.configure {
      $0.mode = .half
      $0.isEditable = true
      $0.renderMode = .image
      // Use SF Symbols as local image resources for copy-ready demos.
      $0.selectedImage = UIImage(systemName: "star.fill")
      $0.unselectedImage = UIImage(systemName: "star")
      $0.halfImage = UIImage(systemName: "star.leadinghalf.filled")
      $0.starSize = CGSize(width: 26, height: 26)
      $0.starSpacing = 10
    }
    imageStyleRating.setRating(3.5, notify: false)
    imageStyleRating.heightAnchor.constraint(equalToConstant: 30).isActive = true
    stackView.addArrangedSubview(imageStyleRating)
  }

  func addModeSwitchingExample() {
    stackView.addArrangedSubview(makeHeader("8) Solid color mode & image mode switching"))
    switchModeRating
      .withMode(.half)
      .withEditable(true)
      .withColors(selected: .systemIndigo, unselected: .systemGray4)
    switchModeRating.setRating(2.5, notify: false)
    switchModeRating.heightAnchor.constraint(equalToConstant: 28).isActive = true
    stackView.addArrangedSubview(switchModeRating)

    let modeSwitchButton = UIButton(type: .system)
    modeSwitchButton.setTitle("Toggle Color/Image Mode", for: .normal)
    modeSwitchButton.addTarget(self, action: #selector(toggleRenderMode), for: .touchUpInside)
    stackView.addArrangedSubview(modeSwitchButton)
  }

  func addCallbackPanel() {
    stackView.addArrangedSubview(makeHeader("9) Real-time rating callback & finish callback"))
    callbackLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    callbackLabel.textColor = .secondaryLabel
    callbackLabel.numberOfLines = 0
    callbackLabel.text = "Interact with rating views to observe callbacks..."
    stackView.addArrangedSubview(callbackLabel)
  }

  // MARK: - Actions

  @objc
  func resetAllRatings() {
    [fullEditableRating, halfDisplayRating, preciseContinuousRating, readOnlyRating, threeStarRating, tenStarRating, imageStyleRating, switchModeRating].forEach {
      $0.resetRating()
    }
    callbackLabel.text = "All ratings reset to minimum values."
  }

  @objc
  func setAllToFourPointFive() {
    [fullEditableRating, halfDisplayRating, preciseContinuousRating, readOnlyRating, imageStyleRating, switchModeRating].forEach {
      $0.setRating(4.5)
    }
    threeStarRating.setRating(2.5)
    tenStarRating.setRating(9)
    callbackLabel.text = "Manual set rating completed."
  }

  @objc
  func toggleRenderMode() {
    switchModeRating.configure {
      if $0.renderMode == .color {
        $0.renderMode = .image
        $0.selectedImage = UIImage(systemName: "heart.fill")
        $0.unselectedImage = UIImage(systemName: "heart")
        $0.halfImage = UIImage(systemName: "heart.leadinghalf.filled")
      } else {
        $0.renderMode = .color
        $0.selectedColor = .systemIndigo
        $0.unselectedColor = .systemGray4
      }
    }
  }

  // MARK: - UI Factory

  func makeHeader(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .semibold)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}
