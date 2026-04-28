import UIKit
import FKUIKit

/// An index of `FKPresentationController` examples, grouped by topic.
///
/// This is designed to be browsable and copy-friendly: each row navigates to a single focused example page.
final class FKPresentationControllerExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Mode",
      rows: [
        Row(
          title: "Bottom sheet — Basics",
          subtitle: "The simplest presentation with defaults and recommended usage notes.",
          make: { BottomSheetBasicsExampleViewController() }
        ),
        Row(
          title: "Top sheet — Basics",
          subtitle: "A top-attached sheet and common use cases (e.g. drop-down trays).",
          make: { TopSheetBasicsExampleViewController() }
        ),
        Row(
          title: "Center — Basics",
          subtitle: "Fixed vs fitted sizing with max constraints for large screens.",
          make: { CenterModalBasicsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Anchor",
      rows: [
        Row(
          title: "Top anchor popup",
          subtitle: "Single anchor view at the top; tap it to present and tap again/mask to dismiss.",
          make: { AnchorTopSingleExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Safe Area",
      rows: [
        Row(
          title: "contentRespectsSafeArea",
          subtitle: "Container can touch screen edges; content insets handle safe area.",
          make: { SafeAreaContentRespectsSafeAreaExampleViewController() }
        ),
        Row(
          title: "containerRespectsSafeArea",
          subtitle: "Container itself stays away from safe area for card-like overlays.",
          make: { SafeAreaContainerRespectsSafeAreaExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Sheet",
      rows: [
        Row(
          title: "Detents — Points",
          subtitle: "Two fixed heights + programmatic detent switching via `setDetent`.",
          make: { SheetDetentsPointsExampleViewController() }
        ),
        Row(
          title: "Detents — Fraction",
          subtitle: "Ratio-based detents that adapt across devices.",
          make: { SheetDetentsFractionExampleViewController() }
        ),
        Row(
          title: "Fit to content",
          subtitle: "Dynamic content height changes with a max height safety cap.",
          make: { SheetFitToContentExampleViewController() }
        ),
        Row(
          title: "Grabber on/off",
          subtitle: "Toggle grabber and adjust its size/inset.",
          make: { SheetGrabberExampleViewController() }
        ),
        Row(
          title: "Scroll tracking",
          subtitle: "Table view scrolling + sheet dragging handoff without gesture fighting.",
          make: { SheetScrollTrackingExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Interaction",
      rows: [
        Row(
          title: "Tap to dismiss on/off",
          subtitle: "Why it’s on by default, and when you should disable it.",
          make: { TapToDismissExampleViewController() }
        ),
        Row(
          title: "Swipe to dismiss on/off",
          subtitle: "Compare thresholds and cancellation feel with live controls.",
          make: { SwipeToDismissExampleViewController() }
        ),
        Row(
          title: "Interactive progress callback",
          subtitle: "Use progress updates to drive UI (e.g. a progress label).",
          make: { InteractiveDismissProgressExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Animation",
      rows: [
        Row(
          title: "Preset gallery",
          subtitle: "Switch presets (systemLike/spring/ease/fade/none) and compare motion.",
          make: { AnimationPresetGalleryExampleViewController() }
        ),
        Row(
          title: "Custom timing",
          subtitle: "When you need explicit duration/curve/spring tuning.",
          make: { CustomAnimationTimingExampleViewController() }
        ),
        Row(
          title: "Reduce Motion aware",
          subtitle: "Select gentler animation when Reduce Motion is enabled at runtime.",
          make: { ReduceMotionCompatibleAnimationExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Backdrop",
      rows: [
        Row(
          title: "Dim backdrop",
          subtitle: "Adjust alpha with a slider and understand readability trade-offs.",
          make: { DimBackdropExampleViewController() }
        ),
        Row(
          title: "Blur backdrop",
          subtitle: "Compare blur styles and note performance considerations.",
          make: { BlurBackdropExampleViewController() }
        ),
        Row(
          title: "Liquid Glass (iOS 26+)",
          subtitle: "Use liquid glass when available, otherwise fall back to blur and show it in UI.",
          make: { LiquidGlassBackdropExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Keyboard",
      rows: [
        Row(
          title: "Keyboard avoidance strategies",
          subtitle: "Compare adjustContainer vs adjustContentInsets for form vs list content.",
          make: { KeyboardAvoidanceExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Rotation",
      rows: [
        Row(
          title: "Rotation resilience",
          subtitle: "Rotate the device: frames stay stable (especially important for anchors).",
          make: { RotationResilienceExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Appearance",
      rows: [
        Row(
          title: "Corner radius / shadow / border",
          subtitle: "Tune visuals with sliders and see results immediately.",
          make: { ContainerAppearanceTuningExampleViewController() }
        ),
        Row(
          title: "Background interaction policy",
          subtitle: "Allow or block touches to the presenting UI (powerful but risky).",
          make: { BackgroundInteractionPolicyExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"
    view.backgroundColor = .systemGroupedBackground
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var configuration = cell.defaultContentConfiguration()
    configuration.text = row.title
    configuration.secondaryText = row.subtitle
    configuration.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = configuration
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}

