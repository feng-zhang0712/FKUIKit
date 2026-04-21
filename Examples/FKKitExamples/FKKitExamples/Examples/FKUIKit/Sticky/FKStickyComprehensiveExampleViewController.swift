//
// FKStickyComprehensiveExampleViewController.swift
//

import FKUIKit
import UIKit

/// Demonstrates multi-target chained sticky with runtime controls.
final class FKStickyComprehensiveExampleViewController: UIViewController, UIScrollViewDelegate {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let primaryBar = UILabel()
  private let secondaryBar = UILabel()
  private let statusLabel = UILabel()
  private var stickyEnabled = true

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sticky Playground"
    view.backgroundColor = .systemBackground
    setupViewTree()
    setupSticky()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.fk_reloadStickyLayout()
  }

  private func setupViewTree() {
    scrollView.delegate = self
    scrollView.alwaysBounceVertical = true
    view.addSubview(scrollView)
    scrollView.frame = view.bounds
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    stackView.axis = .vertical
    stackView.spacing = 12
    stackView.layoutMargins = .init(top: 16, left: 16, bottom: 20, right: 16)
    stackView.isLayoutMarginsRelativeArrangement = true
    scrollView.addSubview(stackView)

    let contentWidth = view.bounds.width - 32
    stackView.frame = .init(x: 0, y: 0, width: contentWidth, height: 0)

    statusLabel.numberOfLines = 0
    statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
    statusLabel.textColor = .secondaryLabel
    statusLabel.text = "Scroll to observe sticky lifecycle callbacks."
    stackView.addArrangedSubview(statusLabel)

    primaryBar.text = "Primary Sticky Bar"
    primaryBar.font = .boldSystemFont(ofSize: 16)
    primaryBar.textAlignment = .center
    primaryBar.backgroundColor = .systemGray5
    primaryBar.layer.cornerRadius = 10
    primaryBar.layer.masksToBounds = true
    primaryBar.heightAnchor.constraint(equalToConstant: 52).isActive = true
    stackView.addArrangedSubview(primaryBar)

    stackView.addArrangedSubview(makeSpacer(height: 240))

    secondaryBar.text = "Secondary Sticky Bar"
    secondaryBar.font = .boldSystemFont(ofSize: 16)
    secondaryBar.textAlignment = .center
    secondaryBar.backgroundColor = .systemGray5
    secondaryBar.layer.cornerRadius = 10
    secondaryBar.layer.masksToBounds = true
    secondaryBar.heightAnchor.constraint(equalToConstant: 52).isActive = true
    stackView.addArrangedSubview(secondaryBar)

    let toggleButton = UIButton(type: .system)
    toggleButton.configuration = .filled()
    toggleButton.configuration?.title = "Toggle Sticky"
    toggleButton.addTarget(self, action: #selector(toggleSticky), for: .touchUpInside)
    stackView.addArrangedSubview(toggleButton)

    for idx in 0..<20 {
      let card = UILabel()
      card.numberOfLines = 0
      card.text = "Reusable content block #\(idx + 1)\nSupports dynamic height and rotation relayout."
      card.backgroundColor = .secondarySystemGroupedBackground
      card.layer.cornerRadius = 12
      card.layer.masksToBounds = true
      card.textAlignment = .left
      card.font = .systemFont(ofSize: 14, weight: .regular)
      card.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
      stackView.addArrangedSubview(card)
    }

    stackView.layoutIfNeeded()
    stackView.frame.size.height = stackView.systemLayoutSizeFitting(
      CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height)
    ).height
    scrollView.contentSize = CGSize(width: view.bounds.width, height: stackView.frame.height + 24)
  }

  private func setupSticky() {
    var configuration = FKStickyConfiguration.default
    configuration.additionalTopInset = 8
    configuration.onDidScroll = { [weak self] _, offsetY in
      self?.statusLabel.text = "offsetY: \(Int(offsetY.rounded()))"
    }
    scrollView.fk_stickyEngine.apply(configuration: configuration)

    let firstThreshold = primaryBar.frame.minY
    let secondThreshold = secondaryBar.frame.minY
    scrollView.fk_stickyEngine.setTargets([
      makeTarget(id: "primary", view: primaryBar, threshold: firstThreshold),
      makeTarget(id: "secondary", view: secondaryBar, threshold: secondThreshold)
    ])
  }

  private func makeTarget(id: String, view: UIView, threshold: CGFloat) -> FKStickyTarget {
    FKStickyTarget(
      id: id,
      viewProvider: { [weak view] in view },
      threshold: threshold,
      onStyleChanged: { style, view in
        view.backgroundColor = style == .sticky ? .systemBlue : .systemGray5
        (view as? UILabel)?.textColor = style == .sticky ? .white : .label
      },
      onStateChanged: { [weak self] state in
        self?.statusLabel.text = "\(state)"
      }
    )
  }

  @objc
  private func toggleSticky() {
    stickyEnabled.toggle()
    scrollView.fk_stickyEngine.setEnabled(stickyEnabled)
    statusLabel.text = stickyEnabled ? "Sticky enabled" : "Sticky disabled"
  }

  private func makeSpacer(height: CGFloat) -> UIView {
    let spacer = UIView()
    spacer.backgroundColor = .clear
    spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
    return spacer
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollView.fk_handleStickyScroll()
  }
}
