import UIKit
import FKUIKit

/// `fk_showSkeleton` / `fk_hideSkeleton` overlay mode with toggles for safe area and interaction blocking.
final class FKSkeletonExampleOverlayViewController: UIViewController {

  private let card = FKSkeletonExampleLayout.borderedHostView()
  private let innerLabel = UILabel()
  private let safeAreaSwitch = UISwitch()
  private let blocksInteractionSwitch = UISwitch()
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Overlay"
    view.backgroundColor = .systemBackground

    innerLabel.text = "Content under overlay"
    innerLabel.textAlignment = .center
    innerLabel.font = .preferredFont(forTextStyle: .body)

    card.translatesAutoresizingMaskIntoConstraints = false
    innerLabel.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(innerLabel)
    NSLayoutConstraint.activate([
      innerLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
      innerLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      innerLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      innerLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
    ])

    safeAreaSwitch.isOn = false
    blocksInteractionSwitch.isOn = true

    let safeRow = labeledRow(title: "respectsSafeArea on overlay", toggle: safeAreaSwitch)
    let blockRow = labeledRow(title: "blocksInteraction", toggle: blocksInteractionSwitch)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    refreshStatus()

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Places FKSkeletonView on top of the card. Toggle safe area to see pinning on full-screen roots; disable blocking to allow taps through the overlay."
    ))
    stack.addArrangedSubview(card)
    NSLayoutConstraint.activate([
      card.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
    ])
    stack.addArrangedSubview(safeRow)
    stack.addArrangedSubview(blockRow)
    stack.addArrangedSubview(statusLabel)
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show overlay", primaryAction: UIAction { [weak self] _ in
      self?.showOverlay()
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide overlay", primaryAction: UIAction { [weak self] _ in
      self?.hideOverlay()
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "FKSkeletonConfiguration.transitionDuration drives the fade used by fk_showSkeleton / fk_hideSkeleton."
    ))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show overlay · transitionDuration 1.2s", primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      var c = FKSkeleton.defaultConfiguration
      c.transitionDuration = 1.2
      self.card.fk_showSkeleton(
        configuration: c,
        animated: true,
        respectsSafeArea: self.safeAreaSwitch.isOn,
        blocksInteraction: self.blocksInteractionSwitch.isOn
      )
      self.refreshStatus()
    }))
  }

  private func labeledRow(title: String, toggle: UISwitch) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.numberOfLines = 0
    let row = UIStackView(arrangedSubviews: [label, toggle])
    row.spacing = 12
    row.alignment = .center
    return row
  }

  private func refreshStatus() {
    statusLabel.text = "fk_isShowingSkeleton == \(card.fk_isShowingSkeleton)"
  }

  private func showOverlay() {
    card.fk_showSkeleton(
      animated: true,
      respectsSafeArea: safeAreaSwitch.isOn,
      blocksInteraction: blocksInteractionSwitch.isOn
    )
    refreshStatus()
  }

  private func hideOverlay() {
    card.fk_hideSkeleton(animated: true) { [weak self] in
      self?.refreshStatus()
    }
  }
}
