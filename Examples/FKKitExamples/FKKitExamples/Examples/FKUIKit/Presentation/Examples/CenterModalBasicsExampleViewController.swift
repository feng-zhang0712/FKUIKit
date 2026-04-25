import UIKit
import FKUIKit

/// Shows centered presentation sizing strategies.
///
/// Key highlights:
/// - Switch between fixed size and fitted size (with max constraints).
/// - Shows why max constraints matter on iPad / large screens.
final class CenterModalBasicsExampleViewController: FKPresentationExamplePageViewController {
  private enum SizeChoice: Int { case fixed, fitted }

  private var sizeChoice: SizeChoice = .fitted

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Center — Basics",
      subtitle: "A floating centered panel with explicit sizing rules.",
      notes: "Use center mode for dialogs, pickers, and compact editors where a sheet would feel too heavy."
    )

    addView(
      FKExampleControls.segmented(
        title: "Size strategy",
        items: ["Fixed 320×420", "Fitted (max 460×640)"],
        selectedIndex: sizeChoice.rawValue
      ) { [weak self] idx in
        self?.sizeChoice = SizeChoice(rawValue: idx) ?? .fitted
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var config = FKPresentationConfiguration.default
      config.mode = .center
      config.center.size = {
        switch self.sizeChoice {
        case .fixed:
          return .fixed(.init(width: 320, height: 420))
        case .fitted:
          return .fitted(maxSize: .init(width: 460, height: 640))
        }
      }()
      _ = FKPresentationExampleHelpers.present(from: self, title: "Center modal", configuration: config)
    }
  }
}

