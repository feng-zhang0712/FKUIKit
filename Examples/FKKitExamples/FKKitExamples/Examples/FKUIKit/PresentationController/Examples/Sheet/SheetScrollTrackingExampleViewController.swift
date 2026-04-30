import UIKit
import FKUIKit

/// Shows scroll tracking handoff between a scroll view and the sheet pan gesture.
///
/// Key highlights:
/// - Content is a `UITableViewController`.
/// - Uses `.explicit` tracking to avoid ambiguity when multiple scroll views exist.
/// Caveat:
/// - Always capture the scroll view weakly to avoid retain cycles.
final class SheetScrollTrackingExampleViewController: FKPresentationExamplePageViewController {
  private var trackingIndex: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Scroll tracking",
      subtitle: "A table view inside a sheet, without gesture fighting.",
      notes: """
      Try this:
      - Scroll the table to the top, then drag downward to dismiss.
      - Scroll to the bottom, then drag upward to expand.
      """
    )

    addView(
      FKExampleControls.segmented(
        title: "Tracking strategy",
        items: ["Explicit", "Automatic", "Disabled"],
        selectedIndex: trackingIndex
      ) { [weak self] idx in
        self?.trackingIndex = idx
      }
    )

    addPrimaryButton(title: "Present table") { [weak self] in
      guard let self else { return }

      let tableVC = FKExampleTableContentViewController(rowCount: 60)
      tableVC.title = "Scrollable content"

      var configuration = FKPresentationConfiguration.default
      configuration.layout = .bottomSheet(configuration.sheet)
      configuration.sheet.detents = [.fraction(0.35), .full]

      switch self.trackingIndex {
      case 0:
        configuration.sheet.scrollTrackingStrategy = .explicit(FKWeakReference(tableVC.tableView))
      case 1:
        configuration.sheet.scrollTrackingStrategy = .automatic
      default:
        configuration.sheet.scrollTrackingStrategy = .disabled
      }

      FKPresentationController.present(
        contentController: tableVC,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(),
        animated: true,
        completion: nil
      )
    }
  }
}

