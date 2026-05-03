import UIKit

/// Skeleton demo hub (`Examples/.../Skeleton/Hub`). Scenario view controllers live in `Scenarios/`; shared UI in `Support/`.
final class FKSkeletonExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: "Overlay on UIView",
      subtitle: "fk_showSkeleton / fk_hideSkeleton · safe area · blocksInteraction · fk_isShowingSkeleton",
      make: { FKSkeletonExampleOverlayViewController() }
    ),
    Row(
      title: "Auto skeleton & display options",
      subtitle: "fk_showAutoSkeleton · FKSkeletonDisplayOptions · fk_isSkeletonExcluded · excludedViews",
      make: { FKSkeletonExampleAutoDisplayOptionsViewController() }
    ),
    Row(
      title: "Per-view overrides & convenience",
      subtitle: "fk_skeletonShape · fk_skeletonConfigurationOverride · fk_showSkeletonLabel/Image/Button/TextField",
      make: { FKSkeletonExampleOverridesViewController() }
    ),
    Row(
      title: "Loading helpers",
      subtitle: "fk_setSkeletonLoading · fk_withSkeletonLoading (token race)",
      make: { FKSkeletonExampleLoadingHelpersViewController() }
    ),
    Row(
      title: "FKSkeletonManager",
      subtitle: "shared.show / hide on a host view (same pipeline as convenience APIs)",
      make: { FKSkeletonExampleManagerViewController() }
    ),
    Row(
      title: "Animation effects",
      subtitle: "FKSkeletonAnimationMode · shimmer directions · pulse · breathing · live preview",
      make: { FKSkeletonExampleAnimationEffectsViewController() }
    ),
    Row(
      title: "Standalone FKSkeletonView",
      subtitle: "animation modes · FKSkeletonStyle · shimmer directions · gradient · border · breathing",
      make: { FKSkeletonExampleStandaloneBlocksViewController() }
    ),
    Row(
      title: "FKSkeletonContainerView",
      subtitle: "usesUnifiedShimmer · hide completion · refreshSkeletonAppearanceForCurrentTraits",
      make: { FKSkeletonExampleContainerViewController() }
    ),
    Row(
      title: "Presets",
      subtitle: "listRow · card · textBlock · gridCell · FKSkeletonAvatarStyle",
      make: { FKSkeletonExamplePresetsViewController() }
    ),
    Row(
      title: "Global defaultConfiguration",
      subtitle: "FKSkeleton.defaultConfiguration (restored when you leave this screen)",
      make: { FKSkeletonExampleGlobalDefaultsViewController() }
    ),
    Row(
      title: "UITableView · skeleton cell",
      subtitle: "FKSkeletonTableViewCell + skeletonContainer",
      make: { FKSkeletonExampleTableSkeletonCellViewController() }
    ),
    Row(
      title: "UITableView · overlay on visible cells",
      subtitle: "fk_showSkeletonOnVisibleCells / fk_hideSkeletonOnVisibleCells",
      make: { FKSkeletonExampleTableOverlayVisibleViewController() }
    ),
    Row(
      title: "UICollectionView · skeleton cell",
      subtitle: "FKSkeletonCollectionViewCell",
      make: { FKSkeletonExampleCollectionSkeletonCellViewController() }
    ),
    Row(
      title: "UICollectionView · auto on visible cells",
      subtitle: "fk_showAutoSkeletonOnVisibleCells / fk_hideAutoSkeletonOnVisibleCells",
      make: { FKSkeletonExampleCollectionAutoVisibleViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSkeleton"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 76
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
