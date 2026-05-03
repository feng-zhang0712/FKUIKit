import UIKit

public extension UILabel {
  /// Auto skeleton with `hidesTargetView = true` tuned for single-line text placeholders.
  func fk_showSkeletonLabel(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}

public extension UIImageView {
  /// Auto skeleton with `hidesTargetView = true` tuned for bitmap placeholders.
  func fk_showSkeletonImage(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}

public extension UIButton {
  /// Auto skeleton with `hidesTargetView = true` tuned for tappable chrome.
  func fk_showSkeletonButton(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}

public extension UITextField {
  /// Auto skeleton with `hidesTargetView = true` tuned for editable fields.
  func fk_showSkeletonTextField(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}
