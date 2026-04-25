import UIKit
import FKUIKit

/// Encourages rotating the device while an anchored presentation is visible.
///
/// Key highlights:
/// - Anchor mode relies on resolving the source geometry; rotation/size changes must keep alignment stable.
/// Caveat:
/// - If your anchor view is inside an animating hierarchy, use a stable view (or a rect provider) as the anchor source.
final class RotationResilienceExampleViewController: FKPresentationExamplePageViewController {
  private let anchorBar = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Rotation resilience",
      subtitle: "Rotate the device after presenting; alignment should remain stable.",
      notes: "This is especially important for anchor-based menus (navigation/tab attachments)."
    )

    addView(FKExampleControls.infoLabel(text: "Steps: 1) Tap Present. 2) Rotate the device. 3) The anchored frame should keep tracking the anchor view."))

    anchorBar.backgroundColor = .quaternarySystemFill
    anchorBar.layer.cornerRadius = 12
    anchorBar.translatesAutoresizingMaskIntoConstraints = false
    anchorBar.heightAnchor.constraint(equalToConstant: 52).isActive = true

    let label = UILabel()
    label.text = "Rotate with this as anchor"
    label.font = .preferredFont(forTextStyle: .headline)
    label.translatesAutoresizingMaskIntoConstraints = false
    anchorBar.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: anchorBar.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: anchorBar.centerYAnchor),
    ])

    addView(anchorBar)

    addPrimaryButton(title: "Present anchored panel") { [weak self] in
      guard let self else { return }
      let anchor = FKAnchor(sourceView: self.anchorBar, edge: .bottom, direction: .auto, alignment: .fill, widthPolicy: .matchContainer, offset: 8)
      var config = FKPresentationConfiguration.default
      config.mode = .anchor(anchor)
      config.sheet.detents = [.fixed(240), .fraction(0.6)]
      config.rotationHandling = .relayoutAnimated
      _ = FKPresentationExampleHelpers.present(from: self, title: "Rotate the device", configuration: config)
    }
  }
}

