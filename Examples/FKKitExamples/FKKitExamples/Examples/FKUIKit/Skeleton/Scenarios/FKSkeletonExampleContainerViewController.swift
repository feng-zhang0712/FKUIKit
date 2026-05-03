import UIKit
import FKUIKit

/// Composable container: unified shimmer toggle, grouped hide completion, trait refresh.
final class FKSkeletonExampleContainerViewController: UIViewController {

  private let container = FKSkeletonContainerView()
  private let completionLabel = UILabel()
  private let unifiedSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Container"
    view.backgroundColor = .systemBackground

    unifiedSwitch.isOn = container.usesUnifiedShimmer
    unifiedSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.container.usesUnifiedShimmer = self.unifiedSwitch.isOn
      self.container.showSkeleton(animated: false)
    }, for: .valueChanged)

    container.translatesAutoresizingMaskIntoConstraints = false
    buildBlocks(in: container)

    completionLabel.font = .preferredFont(forTextStyle: .footnote)
    completionLabel.textColor = .secondaryLabel
    completionLabel.numberOfLines = 0
    completionLabel.text = "hideSkeleton completion has not fired yet."

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "FKSkeletonContainerView coordinates child FKSkeletonView instances. usesUnifiedShimmer shares one masked gradient (performance); each child sets isShimmerSuppressed automatically so only the host draws motion. Turning unified mode off lets every block animate its own gradient."
    ))
    stack.addArrangedSubview(labeledSwitch(title: "usesUnifiedShimmer", toggle: unifiedSwitch))
    stack.addArrangedSubview(container)
    NSLayoutConstraint.activate([
      container.heightAnchor.constraint(equalToConstant: 120),
    ])
    stack.addArrangedSubview(completionLabel)

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show skeleton", primaryAction: UIAction { [weak self] _ in
      self?.container.showSkeleton(animated: true)
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide with completion", primaryAction: UIAction { [weak self] _ in
      self?.container.hideSkeleton(animated: true) { [weak self] in
        self?.completionLabel.text = "hideSkeleton completion fired at \(Self.timeString())"
      }
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "refreshSkeletonAppearanceForCurrentTraits()", primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      self.container.skeletonSubviews.forEach { $0.refreshSkeletonAppearanceForCurrentTraits() }
      var cfg = self.container.configuration ?? FKSkeleton.defaultConfiguration
      cfg.animationDuration = cfg.animationDuration
      self.container.configuration = cfg
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Trait refresh reapplies dynamic UIColor snapshots on layers. Toggle Light/Dark in Settings or use Xcode Environment Overrides while this screen is visible."
    ))

    container.showSkeleton(animated: false)
  }

  private func buildBlocks(in container: FKSkeletonContainerView) {
    let avatar = FKSkeletonView()
    avatar.layer.cornerRadius = 28
    avatar.configuration = {
      var c = FKSkeletonConfiguration()
      c.animationDuration = 1.1
      return c
    }()

    let line1 = FKSkeletonView()
    line1.layer.cornerRadius = 4
    let line2 = FKSkeletonView()
    line2.layer.cornerRadius = 4

    [avatar, line1, line2].forEach { container.addSkeletonSubview($0) }

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 56),
      avatar.heightAnchor.constraint(equalToConstant: 56),

      line1.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      line1.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      line1.heightAnchor.constraint(equalToConstant: 14),
      line1.bottomAnchor.constraint(equalTo: container.centerYAnchor, constant: -4),

      line2.leadingAnchor.constraint(equalTo: line1.leadingAnchor),
      line2.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.55),
      line2.heightAnchor.constraint(equalToConstant: 12),
      line2.topAnchor.constraint(equalTo: container.centerYAnchor, constant: 4),
    ])
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

  private static func timeString() -> String {
    let f = DateFormatter()
    f.timeStyle = .medium
    f.dateStyle = .none
    return f.string(from: Date())
  }
}
