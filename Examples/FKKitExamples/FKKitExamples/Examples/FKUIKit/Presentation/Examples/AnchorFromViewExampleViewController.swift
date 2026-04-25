import UIKit
import FKUIKit

/// Anchors a presentation to a full-width view inside the page.
///
/// Key highlights:
/// - Uses `FKPresentationMode.anchor(_:)` with `.auto` direction.
/// - Shows a stable “attachment line” that updates during layout changes.
/// Caveat:
/// - Your anchor view must be in a window at presentation time; otherwise FK will fall back safely.
final class AnchorFromViewExampleViewController: FKPresentationExamplePageViewController {
  private let anchorBar = UIView()
  private var directionIndex: Int = 2

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Anchor — From a view",
      subtitle: "Expand from a full-width anchor view, up or down.",
      notes: "Use `.auto` direction when the available space can change (rotation, split view, keyboard)."
    )

    anchorBar.backgroundColor = .tertiarySystemFill
    anchorBar.layer.cornerRadius = 12
    anchorBar.translatesAutoresizingMaskIntoConstraints = false
    anchorBar.heightAnchor.constraint(equalToConstant: 56).isActive = true

    let anchorLabel = UILabel()
    anchorLabel.text = "Anchor view (tap Present)"
    anchorLabel.font = .preferredFont(forTextStyle: .headline)
    anchorLabel.textColor = .label
    anchorLabel.translatesAutoresizingMaskIntoConstraints = false
    anchorBar.addSubview(anchorLabel)
    NSLayoutConstraint.activate([
      anchorLabel.centerXAnchor.constraint(equalTo: anchorBar.centerXAnchor),
      anchorLabel.centerYAnchor.constraint(equalTo: anchorBar.centerYAnchor),
    ])

    addView(anchorBar)

    addView(
      FKExampleControls.segmented(
        title: "Direction",
        items: ["Up", "Down", "Auto"],
        selectedIndex: directionIndex
      ) { [weak self] idx in
        self?.directionIndex = idx
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let direction: FKAnchor.Direction = {
        switch self.directionIndex {
        case 0: return .up
        case 1: return .down
        default: return .auto
        }
      }()

      let anchor = FKAnchor(sourceView: self.anchorBar, edge: .bottom, direction: direction, alignment: .fill, widthPolicy: .matchContainer, offset: 8)
      var config = FKPresentationConfiguration.default
      config.mode = .anchor(anchor)
      config.allowsSwipeToDismiss = true
      config.sheet.detents = [.fitContent, .fraction(0.6)]

      _ = FKPresentationExampleHelpers.present(from: self, title: "Anchored panel", configuration: config)
    }
  }
}

