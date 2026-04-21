//
// FKCarouselComprehensiveExampleViewController.swift
//
// Comprehensive FKCarousel example covering core scenarios.
//

import FKUIKit
import UIKit

/// A scrollable showcase that covers all core FKCarousel capabilities.
final class FKCarouselComprehensiveExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let logTextView = UITextView()
  private let dynamicCarousel = FKCarousel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Comprehensive"
    view.backgroundColor = .systemBackground
    setupLayout()
    buildSections()
  }
}

private extension FKCarouselComprehensiveExampleViewController {
  func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 20
    stackView.alignment = .fill
    stackView.distribution = .fill

    view.addSubview(scrollView)
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

  func buildSections() {
    addSection(
      title: "1) Basic infinite carousel with local images",
      subtitle: "Default infinite loop + default auto scroll.",
      carousel: makeBasicLocalCarousel()
    )

    addSection(
      title: "2) Network images with placeholder and failure image",
      subtitle: "One invalid URL is intentionally added to show fallback rendering.",
      carousel: makeNetworkCarousel()
    )

    addSection(
      title: "3) Custom UIView card carousel",
      subtitle: "Uses custom view provider for reuse-safe infinite looping.",
      carousel: makeCustomCardCarousel()
    )

    addSection(
      title: "4) Horizontal and vertical carousel",
      subtitle: "Top is horizontal, bottom is vertical.",
      customBody: makeDirectionDemoBody()
    )

    addSection(
      title: "5) Custom pageControl and custom auto interval",
      subtitle: "Right-aligned control with custom dot color and size.",
      carousel: makeCustomPageControlCarousel()
    )

    addSection(
      title: "6) Single item adaptation (loop/swipe disabled automatically)",
      subtitle: "Only one item is provided to verify adaptation behavior.",
      carousel: makeSingleItemCarousel()
    )

    addSection(
      title: "7) Dynamic update + manual pause/resume auto scroll",
      subtitle: "Includes callback logs, dynamic source update, and playback controls.",
      customBody: makeDynamicDemoBody()
    )
  }

  func addSection(title: String, subtitle: String, carousel: FKCarousel) {
    let card = makeSectionCard(title: title, subtitle: subtitle)
    card.addArrangedSubview(carousel)
    carousel.heightAnchor.constraint(equalToConstant: 170).isActive = true
    stackView.addArrangedSubview(card)
  }

  func addSection(title: String, subtitle: String, customBody: UIView) {
    let card = makeSectionCard(title: title, subtitle: subtitle)
    card.addArrangedSubview(customBody)
    stackView.addArrangedSubview(card)
  }

  func makeSectionCard(title: String, subtitle: String) -> UIStackView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 10
    container.translatesAutoresizingMaskIntoConstraints = false
    container.isLayoutMarginsRelativeArrangement = true
    container.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
    container.backgroundColor = .secondarySystemGroupedBackground
    container.layer.cornerRadius = 12
    container.layer.masksToBounds = true

    let titleLabel = UILabel()
    titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.text = title

    let subtitleLabel = UILabel()
    subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = subtitle

    container.addArrangedSubview(titleLabel)
    container.addArrangedSubview(subtitleLabel)
    return container
  }

  func makeBasicLocalCarousel() -> FKCarousel {
    let carousel = FKCarousel()
    carousel.translatesAutoresizingMaskIntoConstraints = false
    carousel.apply(configuration: FKCarouselConfiguration())
    carousel.reload(items: FKCarouselDemoSupport.localImageItems())
    carousel.onItemSelected = { [weak self] index, _ in
      self?.appendLog("Local carousel tapped: \(index)")
    }
    carousel.onPageChanged = { [weak self] index in
      self?.appendLog("Local carousel page: \(index)")
    }
    return carousel
  }

  func makeNetworkCarousel() -> FKCarousel {
    let carousel = FKCarousel()
    carousel.translatesAutoresizingMaskIntoConstraints = false

    var config = FKCarouselConfiguration()
    config.placeholderImage = FKCarouselDemoSupport.placeholderImage()
    config.failureImage = FKCarouselDemoSupport.failureImage()
    config.autoScrollInterval = 2.4
    carousel.apply(configuration: config)
    carousel.reload(items: FKCarouselDemoSupport.remoteImageItems())
    return carousel
  }

  func makeCustomCardCarousel() -> FKCarousel {
    let carousel = FKCarousel()
    carousel.translatesAutoresizingMaskIntoConstraints = false
    // Chain-style configuration using helper.
    carousel.apply(configuration: FKCarouselDemoSupport.makeConfig { config in
      config.autoScrollInterval = 2.0
      config.containerStyle.cornerRadius = 16
    })
    carousel.reload(items: FKCarouselDemoSupport.customCardItems())
    return carousel
  }

  func makeDirectionDemoBody() -> UIView {
    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 12

    let horizontal = FKCarousel()
    horizontal.translatesAutoresizingMaskIntoConstraints = false
    horizontal.apply(configuration: FKCarouselConfiguration())
    horizontal.reload(items: FKCarouselDemoSupport.localImageItems())
    horizontal.heightAnchor.constraint(equalToConstant: 150).isActive = true

    let vertical = FKCarousel()
    vertical.translatesAutoresizingMaskIntoConstraints = false
    var config = FKCarouselConfiguration()
    config.direction = .vertical
    config.autoScrollInterval = 1.8
    vertical.apply(configuration: config)
    vertical.reload(items: FKCarouselDemoSupport.localImageItems())
    vertical.heightAnchor.constraint(equalToConstant: 150).isActive = true

    body.addArrangedSubview(horizontal)
    body.addArrangedSubview(vertical)
    return body
  }

  func makeCustomPageControlCarousel() -> FKCarousel {
    let carousel = FKCarousel()
    carousel.translatesAutoresizingMaskIntoConstraints = false

    var dotStyle = FKCarouselPageControlStyle()
    dotStyle.normalColor = UIColor.white.withAlphaComponent(0.35)
    dotStyle.selectedColor = .systemYellow
    dotStyle.normalDotSize = CGSize(width: 6, height: 6)
    dotStyle.selectedDotSize = CGSize(width: 18, height: 6)
    dotStyle.spacing = 7

    var config = FKCarouselConfiguration()
    config.autoScrollInterval = 1.6
    config.pageControlAlignment = .right
    config.pageControlStyle = dotStyle
    config.pageControlInsets = UIEdgeInsets(top: 0, left: 12, bottom: 8, right: 12)
    carousel.apply(configuration: config)
    carousel.reload(items: FKCarouselDemoSupport.localImageItems())
    return carousel
  }

  func makeSingleItemCarousel() -> FKCarousel {
    let carousel = FKCarousel()
    carousel.translatesAutoresizingMaskIntoConstraints = false
    carousel.apply(configuration: FKCarouselConfiguration())
    carousel.reload(items: FKCarouselDemoSupport.singleImageItem())
    return carousel
  }

  func makeDynamicDemoBody() -> UIView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 10

    dynamicCarousel.translatesAutoresizingMaskIntoConstraints = false
    dynamicCarousel.heightAnchor.constraint(equalToConstant: 160).isActive = true
    dynamicCarousel.apply(configuration: FKCarouselConfiguration())
    dynamicCarousel.reload(items: FKCarouselDemoSupport.localImageItems())
    dynamicCarousel.onPageChanged = { [weak self] index in
      self?.appendLog("Dynamic carousel page changed: \(index)")
    }
    dynamicCarousel.onItemSelected = { [weak self] index, _ in
      self?.appendLog("Dynamic carousel tapped: \(index)")
    }

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually

    let pauseButton = makeActionButton(title: "Pause") { [weak self] in
      self?.dynamicCarousel.pauseAutoScroll()
      self?.appendLog("Manual pause auto scroll")
    }
    let resumeButton = makeActionButton(title: "Resume") { [weak self] in
      self?.dynamicCarousel.resumeAutoScroll()
      self?.appendLog("Manual resume auto scroll")
    }
    let updateButton = makeActionButton(title: "Update Data") { [weak self] in
      self?.dynamicCarousel.reload(items: FKCarouselDemoSupport.customCardItems())
      self?.appendLog("Data source updated to custom cards")
    }
    actions.addArrangedSubview(pauseButton)
    actions.addArrangedSubview(resumeButton)
    actions.addArrangedSubview(updateButton)

    logTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logTextView.backgroundColor = .tertiarySystemGroupedBackground
    logTextView.layer.cornerRadius = 8
    logTextView.isEditable = false
    logTextView.heightAnchor.constraint(equalToConstant: 110).isActive = true
    logTextView.text = "Event log:\n"

    container.addArrangedSubview(dynamicCarousel)
    container.addArrangedSubview(actions)
    container.addArrangedSubview(logTextView)
    return container
  }

  func makeActionButton(title: String, action: @escaping () -> Void) -> UIButton {
    let button = ActionButton(type: .system)
    button.setTitle(title, for: .normal)
    button.backgroundColor = .systemBlue
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    button.layer.cornerRadius = 8
    button.layer.masksToBounds = true
    button.onTap = action
    return button
  }

  func appendLog(_ text: String) {
    let existing = logTextView.text ?? ""
    logTextView.text = existing + text + "\n"
    let range = NSRange(location: max(0, (logTextView.text as NSString).length - 1), length: 1)
    logTextView.scrollRangeToVisible(range)
  }
}

private final class ActionButton: UIButton {
  var onTap: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    addTarget(self, action: #selector(handleTap), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    addTarget(self, action: #selector(handleTap), for: .touchUpInside)
  }

  @objc private func handleTap() {
    onTap?()
  }
}
