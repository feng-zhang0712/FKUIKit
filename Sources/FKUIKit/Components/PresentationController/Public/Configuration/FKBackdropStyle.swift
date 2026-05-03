import UIKit

/// Backdrop style behind the presented container.
public enum FKBackdropStyle: Equatable {
  /// No backdrop.
  case none
  /// A dim overlay using dynamic system colors.
  case dim(color: UIColor = UIColor.black, alpha: CGFloat = 0.35)
}

