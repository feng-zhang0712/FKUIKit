#if canImport(UIKit)
import UIKit

public extension UICollectionView {
  /// Reloads data while suppressing implicit animations.
  func fk_reloadDataWithoutAnimation() {
    UIView.performWithoutAnimation {
      reloadData()
      layoutIfNeeded()
    }
  }
}

#endif
