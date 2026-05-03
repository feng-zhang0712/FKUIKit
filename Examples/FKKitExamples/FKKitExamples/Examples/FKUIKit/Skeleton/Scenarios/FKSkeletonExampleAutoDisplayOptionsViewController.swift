import UIKit
import FKUIKit

/// Tree scanning mode with `FKSkeletonDisplayOptions`, exclusions via flag and via array.
final class FKSkeletonExampleAutoDisplayOptionsViewController: UIViewController {

  private let rootStack = UIStackView()
  private let badgeKeepVisible = UILabel()
  private let excludedByArrayHost = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Auto & options"
    view.backgroundColor = .systemBackground

    rootStack.axis = .vertical
    rootStack.spacing = 12
    rootStack.alignment = .fill
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = "Primary title label"
    titleLabel.font = .preferredFont(forTextStyle: .title3)

    let subtitleLabel = UILabel()
    subtitleLabel.text = "Subtitle copy goes here"
    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel

    let icon = UIImageView(image: UIImage(systemName: "photo"))
    icon.contentMode = .scaleAspectFill
    icon.clipsToBounds = true
    icon.layer.cornerRadius = 8
    icon.backgroundColor = .secondarySystemFill
    icon.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      icon.heightAnchor.constraint(equalToConstant: 72),
      icon.widthAnchor.constraint(equalToConstant: 72),
    ])

    badgeKeepVisible.text = "Excluded via fk_isSkeletonExcluded"
    badgeKeepVisible.font = .preferredFont(forTextStyle: .caption1)
    badgeKeepVisible.textAlignment = .center
    badgeKeepVisible.backgroundColor = .systemYellow.withAlphaComponent(0.35)
    badgeKeepVisible.layer.cornerRadius = 6
    badgeKeepVisible.clipsToBounds = true
    badgeKeepVisible.fk_isSkeletonExcluded = true

    let arrayExcludedLabel = UILabel()
    arrayExcludedLabel.text = "Excluded via excludedViews[]"
    arrayExcludedLabel.font = .preferredFont(forTextStyle: .caption1)
    arrayExcludedLabel.textAlignment = .center
    arrayExcludedLabel.backgroundColor = .systemMint.withAlphaComponent(0.35)
    arrayExcludedLabel.layer.cornerRadius = 6
    arrayExcludedLabel.clipsToBounds = true
    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(subtitleLabel)
    let iconRow = UIStackView(arrangedSubviews: [icon, badgeKeepVisible])
    iconRow.spacing = 12
    iconRow.alignment = .center
    rootStack.addArrangedSubview(iconRow)
    rootStack.addArrangedSubview(excludedByArrayHost)
    excludedByArrayHost.addSubview(arrayExcludedLabel)
    arrayExcludedLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      arrayExcludedLabel.topAnchor.constraint(equalTo: excludedByArrayHost.topAnchor, constant: 8),
      arrayExcludedLabel.leadingAnchor.constraint(equalTo: excludedByArrayHost.leadingAnchor, constant: 8),
      arrayExcludedLabel.trailingAnchor.constraint(equalTo: excludedByArrayHost.trailingAnchor, constant: -8),
      arrayExcludedLabel.bottomAnchor.constraint(equalTo: excludedByArrayHost.bottomAnchor, constant: -8),
    ])

    let host = FKSkeletonExampleLayout.borderedHostView()
    host.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: host.topAnchor, constant: 16),
      rootStack.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -16),
    ])

    let hideSwitch = UISwitch()
    let blockSwitch = UISwitch()
    hideSwitch.isOn = true
    blockSwitch.isOn = true

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "fk_showAutoSkeleton walks UIStackView arranged views. Use options.hidesTargetView to dim content and excludedViews / fk_isSkeletonExcluded to keep chrome visible."
    ))
    stack.addArrangedSubview(host)

    stack.addArrangedSubview(labeledSwitch(title: "hidesTargetView", toggle: hideSwitch))
    stack.addArrangedSubview(labeledSwitch(title: "blocksInteraction on host", toggle: blockSwitch))

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show auto skeleton", primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      let excluded: [UIView] = [self.excludedByArrayHost]
      let opts = FKSkeletonDisplayOptions(
        blocksInteraction: blockSwitch.isOn,
        hidesTargetView: hideSwitch.isOn,
        excludedViews: excluded
      )
      self.rootStack.fk_showAutoSkeleton(options: opts, animated: true)
    }))

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide auto skeleton", primaryAction: UIAction { [weak self] _ in
      self?.rootStack.fk_hideAutoSkeleton(animated: true)
    }))
  }

  private func labeledSwitch(title: String, toggle: UISwitch) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.numberOfLines = 0
    let row = UIStackView(arrangedSubviews: [label, toggle])
    row.spacing = 12
    row.alignment = .center
    return row
  }
}
