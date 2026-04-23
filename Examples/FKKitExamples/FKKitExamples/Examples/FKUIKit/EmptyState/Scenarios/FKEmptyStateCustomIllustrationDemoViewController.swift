import FKUIKit
import UIKit

final class FKEmptyStateCustomIllustrationDemoViewController: UIViewController {
  private let container = UIView()
  private let toggle = UISegmentedControl(items: ["Lazy illustration", "Icon only"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Illustration"
    view.backgroundColor = .systemBackground
    buildUI()
    renderLazyIllustration()
  }

  private func buildUI() {
    toggle.selectedSegmentIndex = 0
    toggle.translatesAutoresizingMaskIntoConstraints = false
    toggle.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(toggle)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      toggle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      toggle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      toggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      container.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: 10),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func modeChanged() {
    if toggle.selectedSegmentIndex == 0 {
      renderLazyIllustration()
    } else {
      container.fk_applyEmptyState(FKEmptyStateDemoFactory.makeIconOnlyModel())
    }
  }

  private func renderLazyIllustration() {
    var model = FKEmptyStateDemoFactory.makeBasicModel()
    model.title = "Illustration is loading..."
    model.description = "This demo simulates lazy-loading a custom accessory view."
    model.customAccessoryPlacement = .replaceImage
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.fk_presentMessageAlert(title: "Create", message: "Primary action tapped from custom illustration demo.")
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      guard let self else { return }
      let orb = self.makeOrbIllustration()
      var loaded = model
      loaded.title = "Custom illustration loaded"
      loaded.customAccessoryView = orb
      self.container.fk_applyEmptyState(loaded, animated: true) { [weak self] _ in
        self?.fk_presentMessageAlert(title: "Create", message: "Primary action tapped after lazy illustration load.")
      }
    }
  }

  private func makeOrbIllustration() -> UIView {
    let orb = UIView(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
    orb.translatesAutoresizingMaskIntoConstraints = false
    orb.widthAnchor.constraint(equalToConstant: 88).isActive = true
    orb.heightAnchor.constraint(equalToConstant: 88).isActive = true
    orb.layer.cornerRadius = 44
    orb.backgroundColor = .systemIndigo
    orb.layer.shadowColor = UIColor.systemIndigo.cgColor
    orb.layer.shadowOpacity = 0.35
    orb.layer.shadowRadius = 14
    orb.layer.shadowOffset = CGSize(width: 0, height: 8)
    return orb
  }
}
