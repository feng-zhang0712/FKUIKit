#if canImport(UIKit)
import UIKit

public extension UITableView {
  /// Reloads data while suppressing implicit animations.
  func fk_reloadDataWithoutAnimation() {
    UIView.performWithoutAnimation {
      reloadData()
      layoutIfNeeded()
    }
  }

  /// Deselects the current row with optional animation, if a selection exists.
  func fk_deselectSelectedRow(animated: Bool) {
    if let path = indexPathForSelectedRow {
      deselectRow(at: path, animated: animated)
    }
  }
}

#endif
