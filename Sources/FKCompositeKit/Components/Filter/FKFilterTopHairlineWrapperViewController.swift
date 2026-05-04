import UIKit

/// Internal wrapper that adds a 1px hairline above a panel content controller.
///
/// Why this exists:
/// - The filter tab bar sits directly above the anchored panel; when the sheet attaches flush under the bar,
///   a top separator improves visual separation (matches common filter dropdown patterns).
/// - This wrapper keeps panel controllers simple and reusable (they don't need to know about hairlines).
///
/// Usage:
/// - Typically created by `FKFilterPanelFactory` when `wrapsTopHairline == true`.
final class FKFilterTopHairlineWrapperViewController: UIViewController {
  private let contentVC: UIViewController
  private let hairline = UIView()
  private var hairlineHeightConstraint: NSLayoutConstraint?

  init(contentVC: UIViewController) {
    self.contentVC = contentVC
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override var preferredContentSize: CGSize {
    get {
      let inner = contentVC.preferredContentSize
      guard inner.height > 0 else { return .zero }
      return CGSize(width: inner.width, height: inner.height + currentHairlineHeight())
    }
    set { super.preferredContentSize = newValue }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    hairline.backgroundColor = .separator
    hairline.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hairline)

    addChild(contentVC)
    contentVC.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(contentVC.view)
    contentVC.didMove(toParent: self)

    hairlineHeightConstraint = hairline.heightAnchor.constraint(equalToConstant: currentHairlineHeight())

    NSLayoutConstraint.activate([
      hairline.topAnchor.constraint(equalTo: view.topAnchor),
      hairline.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hairline.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hairlineHeightConstraint,
      contentVC.view.topAnchor.constraint(equalTo: hairline.bottomAnchor),
      contentVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      contentVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      contentVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ].compactMap { $0 })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    hairlineHeightConstraint?.constant = currentHairlineHeight()
  }

  private func currentHairlineHeight() -> CGFloat {
    let scale = view.window?.windowScene?.screen.scale ?? traitCollection.displayScale
    return 1 / max(scale, 1)
  }
}

