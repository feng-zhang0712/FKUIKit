//
// FKSkeletonUIKitExtensions.swift
//

import UIKit

public extension UILabel {
  /// Enables auto-generated skeleton for this label only.
  func fk_showSkeletonLabel(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}

public extension UIImageView {
  /// Enables auto-generated skeleton for this image view only.
  func fk_showSkeletonImage(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}

public extension UIButton {
  /// Enables auto-generated skeleton for this button only.
  func fk_showSkeletonButton(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}

public extension UITextField {
  /// Enables auto-generated skeleton for this text field only.
  func fk_showSkeletonTextField(configuration: FKSkeletonConfiguration? = nil, animated: Bool = true) {
    fk_showAutoSkeleton(configuration: configuration, options: .init(hidesTargetView: true), animated: animated)
  }
}
