import UIKit
import FKUIKit

/// Simulates an anchored tray expanding above a tab bar.
///
/// Key highlights:
/// - Uses an anchor view near the bottom of the screen.
/// - Expands upward to mimic “from tab bar upward” interactions.
final class AnchorAboveTabBarExampleViewController: FKPresentationExamplePageViewController {
  private let anchorStrip = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Anchor — Above tab bar",
      subtitle: "Expand upward from the bottom UI.",
      notes: "If your app uses a real tab bar, anchor to a view that tracks its frame."
    )

    addView(FKExampleControls.infoLabel(text: "This example uses a bottom anchor strip to represent a tab bar attachment line."))

    anchorStrip.backgroundColor = .systemGreen.withAlphaComponent(0.12)
    anchorStrip.layer.cornerRadius = 12
    anchorStrip.translatesAutoresizingMaskIntoConstraints = false
    anchorStrip.heightAnchor.constraint(equalToConstant: 56).isActive = true

    let label = UILabel()
    label.text = "Tab bar attachment line"
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .systemGreen
    label.translatesAutoresizingMaskIntoConstraints = false
    anchorStrip.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: anchorStrip.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: anchorStrip.centerYAnchor),
    ])

    // Push the anchor strip towards the bottom so it behaves like a tab bar.
    let pushDown = UIView()
    pushDown.translatesAutoresizingMaskIntoConstraints = false
    pushDown.heightAnchor.constraint(equalToConstant: 420).isActive = true

    addView(pushDown)
    addView(anchorStrip)

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let anchor = FKAnchor(sourceView: self.anchorStrip, edge: .top, direction: .up, alignment: .fill, widthPolicy: .matchContainer, offset: 8)
      var config = FKPresentationConfiguration.default
      config.mode = .anchor(anchor)
      config.sheet.detents = [.fixed(260), .fraction(0.7)]
      _ = FKPresentationExampleHelpers.present(from: self, title: "Above tab bar", configuration: config)
    }
  }
}

