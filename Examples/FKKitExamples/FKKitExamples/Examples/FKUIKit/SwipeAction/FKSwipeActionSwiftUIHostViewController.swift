import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

/// SwiftUI demo page (UIKit host): displays a SwiftUI `List` with FKSwipeAction enabled.
final class FKSwipeActionSwiftUIHostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI: List Swipe Actions"
    view.backgroundColor = .systemBackground

#if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKSwipeActionSwiftUIDemoView())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
#else
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.textAlignment = .center
    label.text = "SwiftUI is not available in the current build environment."
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
    ])
#endif
  }
}

