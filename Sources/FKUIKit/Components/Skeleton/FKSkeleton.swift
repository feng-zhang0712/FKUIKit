//
// FKSkeleton.swift
//

import UIKit

/// Entry point for skeleton loading UI: shared defaults (`defaultConfiguration`) and documentation.
///
/// **Overlay (low-friction)** — add on top of existing views without changing hierarchy:
/// ```
/// view.fk_showSkeleton()
/// view.fk_hideSkeleton()
/// ```
/// Use `respectsSafeArea: true` on full-screen hosts so the overlay follows the safe area.
///
/// **Composable** — build rows/cards with `FKSkeletonContainerView` + `FKSkeletonView`, or use
/// `FKSkeletonPresets`. Containers use **one** shared shimmer (`usesUnifiedShimmer`) by default.
///
/// **Lists** — register `FKSkeletonTableViewCell` / `FKSkeletonCollectionViewCell` with a dedicated
/// reuse identifier; show skeleton rows while loading, then `reloadData` with real cells after fetch.
public final class FKSkeleton {

  private static let defaultConfigurationLock = NSLock()
  /// Protected by `defaultConfigurationLock` in `defaultConfiguration` accessors.
  nonisolated(unsafe) private static var _defaultConfiguration = FKSkeletonConfiguration()

  /// Global defaults applied to all skeletons unless overridden per-instance.
  public static var defaultConfiguration: FKSkeletonConfiguration {
    get {
      defaultConfigurationLock.lock()
      defer { defaultConfigurationLock.unlock() }
      return _defaultConfiguration
    }
    set {
      defaultConfigurationLock.lock()
      defer { defaultConfigurationLock.unlock() }
      _defaultConfiguration = newValue
    }
  }

  private init() {}
}
