import UIKit

/// Maps visible table/collection cells to their `contentView` hosts for skeleton helpers.
enum FKSkeletonVisibleCells {
  static func contentRoots(from cells: [UIView]) -> [UIView] {
    cells.compactMap { cell in
      (cell as? UITableViewCell)?.contentView ?? (cell as? UICollectionViewCell)?.contentView
    }
  }
}
