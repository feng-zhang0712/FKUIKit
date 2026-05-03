import UIKit

/// Internal hook shared by ``FKSkeletonController``; kept module-private so the public surface stays focused on UIView APIs and ``FKSkeletonManager``.
protocol FKSkeletonPresentable: AnyObject {
  func showSkeleton(
    configuration: FKSkeletonConfiguration?,
    options: FKSkeletonDisplayOptions,
    animated: Bool
  )
  func hideSkeleton(animated: Bool, completion: (() -> Void)?)
}
