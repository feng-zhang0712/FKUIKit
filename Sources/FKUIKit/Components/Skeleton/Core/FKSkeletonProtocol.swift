//
// FKSkeletonProtocol.swift
//

import UIKit

/// Minimal protocol abstraction for objects that can show and hide skeletons.
public protocol FKSkeletonPresentable: AnyObject {
  /// Shows skeleton placeholders.
  func showSkeleton(
    configuration: FKSkeletonConfiguration?,
    options: FKSkeletonDisplayOptions,
    animated: Bool
  )

  /// Hides skeleton placeholders.
  func hideSkeleton(animated: Bool, completion: (() -> Void)?)
}
