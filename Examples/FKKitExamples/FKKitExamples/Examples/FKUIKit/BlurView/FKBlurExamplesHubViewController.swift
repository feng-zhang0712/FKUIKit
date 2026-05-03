import UIKit
import FKUIKit

// MARK: - Hub

final class FKBlurViewExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: "Basic Blur View", subtitle: "The simplest FKBlurView (system material)", make: { FKBlurBasicVC() }),
    Row(title: "All System Styles", subtitle: "Preview light/dark/extraLight/systemMaterial…", make: { FKBlurAllSystemStylesVC() }),
    Row(title: "Custom Blur Radius", subtitle: "Custom blurRadius demo", make: { FKBlurCustomRadiusVC() }),
    Row(title: "Custom Saturation", subtitle: "Custom saturation demo", make: { FKBlurCustomSaturationVC() }),
    Row(title: "Custom Brightness", subtitle: "Custom brightness demo", make: { FKBlurCustomBrightnessVC() }),
    Row(title: "Custom Tint Overlay", subtitle: "Custom tintColor + tintOpacity demo", make: { FKBlurCustomTintVC() }),
    Row(title: "Static Blur", subtitle: "mode = .static (blur once, maximum performance)", make: { FKBlurStaticVC() }),
    Row(title: "Dynamic Blur (Scroll)", subtitle: "mode = .dynamic (refresh while scrolling)", make: { FKBlurDynamicScrollVC() }),
    Row(title: "Image Blur", subtitle: "UIImage.fk_blurred(...) demo", make: { FKBlurImageBlurVC() }),
    Row(title: "UIView Snapshot Blur", subtitle: "UIView.fk_blurredSnapshot sync/async demo", make: { FKBlurUIViewSnapshotVC() }),
    Row(title: "Rounded Rect Blur", subtitle: "maskedCornerRadius demo", make: { FKBlurRoundedRectVC() }),
    Row(title: "Circular Blur", subtitle: "maskPath = ovalInRect demo", make: { FKBlurCircleVC() }),
    Row(title: "Custom Mask", subtitle: "Arbitrary maskPath demo", make: { FKBlurCustomMaskVC() }),
    Row(title: "Semi-Transparent Blur", subtitle: "opacity demo", make: { FKBlurOpacityVC() }),
    Row(title: "Global Defaults", subtitle: "FKBlur.defaultConfiguration demo", make: { FKBlurGlobalConfigVC() }),
    Row(title: "XIB / Storyboard", subtitle: "Load a FKBlurView from a XIB", make: { FKBlurXIBDemoVC() }),
    Row(title: "SwiftUI Demo", subtitle: "FKSwiftUIBlurView demo", make: { FKBlurSwiftUIHostVC() }),
    Row(title: "Dark Mode", subtitle: "Switch Light/Dark and inspect materials", make: { FKBlurDarkModeVC() }),
    Row(title: "Rotation", subtitle: "Auto Layout + refresh after rotation", make: { FKBlurRotationVC() }),
    Row(title: "Scroll Performance", subtitle: "Validate smooth 60fps scrolling", make: { FKBlurPerformanceTestVC() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBlurView"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var cfg = cell.defaultContentConfiguration()
    cfg.text = row.title
    cfg.secondaryText = row.subtitle
    cfg.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = cfg
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
