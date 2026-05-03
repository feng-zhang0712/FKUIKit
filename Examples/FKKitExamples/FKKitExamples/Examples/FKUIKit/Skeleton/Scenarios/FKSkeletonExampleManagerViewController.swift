import UIKit
import FKUIKit

/// Explicit `FKSkeletonManager.shared` calls (same behavior as `fk_showAutoSkeleton`).
final class FKSkeletonExampleManagerViewController: UIViewController {

  private let host = FKSkeletonExampleLayout.borderedHostView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSkeletonManager"
    view.backgroundColor = .systemBackground

    let label = UILabel()
    label.text = "Manager host"
    label.textAlignment = .center
    label.font = .preferredFont(forTextStyle: .body)
    label.translatesAutoresizingMaskIntoConstraints = false
    host.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: host.topAnchor, constant: 20),
      label.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -20),
      host.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
    ])

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "FKSkeletonManager.shared.show/hide is what UIView’s fk_showAutoSkeleton wraps. Use when you want an explicit dependency."
    ))
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Manager.show", primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      FKSkeletonManager.shared.show(
        on: self.host,
        configuration: nil,
        options: FKSkeletonDisplayOptions(blocksInteraction: true, hidesTargetView: true, excludedViews: []),
        animated: true
      )
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Manager.hide", primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      FKSkeletonManager.shared.hide(on: self.host, animated: true, completion: nil)
    }))
  }
}
