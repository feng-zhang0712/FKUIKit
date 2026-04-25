import UIKit
import FKUIKit

/// Simulates an anchored menu expanding under a navigation bar.
///
/// Key highlights:
/// - Uses an anchor view placed at the top of the content, aligned with the navigation bar area.
/// - Great for “sort / filter / quick actions” menus that should feel attached to the top UI.
final class AnchorUnderNavigationBarExampleViewController: FKPresentationExamplePageViewController {
  private let anchorStrip = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Anchor — Under navigation bar",
      subtitle: "A common pattern: expand downward from the top UI.",
      notes: "Try rotating the device after presenting to see the anchored layout remain stable."
    )

    anchorStrip.backgroundColor = .systemBlue.withAlphaComponent(0.12)
    anchorStrip.layer.cornerRadius = 12
    anchorStrip.translatesAutoresizingMaskIntoConstraints = false
    anchorStrip.heightAnchor.constraint(equalToConstant: 44).isActive = true

    let label = UILabel()
    label.text = "Navigation bar attachment line"
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .systemBlue
    label.translatesAutoresizingMaskIntoConstraints = false
    anchorStrip.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: anchorStrip.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: anchorStrip.centerYAnchor),
    ])

    addView(anchorStrip)
    addView(FKExampleControls.infoLabel(text: "This anchor view sits below the navigation bar. Presenting expands downward from its bottom edge."))

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let anchor = FKAnchor(sourceView: self.anchorStrip, edge: .bottom, direction: .down, alignment: .fill, widthPolicy: .matchContainer, offset: 8)
      var config = FKPresentationConfiguration.default
      config.mode = .anchor(anchor)
      config.sheet.detents = [.fixed(220), .fraction(0.55)]
      config.safeAreaPolicy = .contentRespectsSafeArea
      _ = FKPresentationExampleHelpers.present(from: self, title: "Under navigation bar", configuration: config)
    }
  }
}

