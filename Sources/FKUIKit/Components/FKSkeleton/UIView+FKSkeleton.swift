//
// UIView+FKSkeleton.swift
//

import ObjectiveC.runtime
import UIKit

// MARK: - Associated object keys

private enum FKSkeletonKeys {
  nonisolated(unsafe) static var overlayView: UInt8 = 0
}

// MARK: - UIView extension

public extension UIView {

  /// Overlays a skeleton on top of this view (does not replace subviews). Safe to call repeatedly.
  ///
  /// - Parameters:
  ///   - respectsSafeArea: When `true`, the overlay is pinned to `safeAreaLayoutGuide` so it does not
  ///     cover the status bar or home indicator on full-screen roots.
  ///   - blocksInteraction: When `true` (default), touches are absorbed by the overlay so underlying
  ///     controls are not triggered while loading.
  func fk_showSkeleton(
    configuration: FKSkeletonConfiguration? = nil,
    animated: Bool = true,
    respectsSafeArea: Bool = false,
    blocksInteraction: Bool = true
  ) {
    fk_skeletonPerformOnMain {
      self.fk_showSkeletonOnMainThread(
        configuration: configuration,
        animated: animated,
        respectsSafeArea: respectsSafeArea,
        blocksInteraction: blocksInteraction
      )
    }
  }

  /// Removes the skeleton overlay. The associated overlay is cleared only after removal completes.
  func fk_hideSkeleton(animated: Bool = true, completion: (() -> Void)? = nil) {
    fk_skeletonPerformOnMain {
      self.fk_hideSkeletonOnMainThread(animated: animated, completion: completion)
    }
  }

  /// Whether a skeleton overlay is currently registered for this view.
  var fk_isShowingSkeleton: Bool {
    fk_skeletonOverlay != nil
  }

  // MARK: - Private storage

  fileprivate var fk_skeletonOverlay: FKSkeletonView? {
    get { objc_getAssociatedObject(self, &FKSkeletonKeys.overlayView) as? FKSkeletonView }
    set { objc_setAssociatedObject(self, &FKSkeletonKeys.overlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  fileprivate func fk_showSkeletonOnMainThread(
    configuration: FKSkeletonConfiguration?,
    animated: Bool,
    respectsSafeArea: Bool,
    blocksInteraction: Bool
  ) {
    let config = configuration ?? FKSkeleton.defaultConfiguration

    if let existing = fk_skeletonOverlay {
      existing.configuration = config
      existing.isUserInteractionEnabled = blocksInteraction
      existing.show(animated: animated)
      return
    }

    let overlay = FKSkeletonView()
    overlay.configuration = config
    overlay.translatesAutoresizingMaskIntoConstraints = false
    overlay.isUserInteractionEnabled = blocksInteraction

    if config.inheritsCornerRadius {
      overlay.layer.cornerRadius = layer.cornerRadius
      overlay.layer.maskedCorners = layer.maskedCorners
    }

    addSubview(overlay)
    if respectsSafeArea {
      NSLayoutConstraint.activate([
        overlay.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
        overlay.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
        overlay.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        overlay.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        overlay.topAnchor.constraint(equalTo: topAnchor),
        overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
        overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
        overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }

    fk_skeletonOverlay = overlay
    overlay.show(animated: animated)
  }

  fileprivate func fk_hideSkeletonOnMainThread(animated: Bool, completion: (() -> Void)?) {
    guard let overlay = fk_skeletonOverlay else {
      completion?()
      return
    }
    overlay.hide(animated: animated) {
      overlay.removeFromSuperview()
      if self.fk_skeletonOverlay === overlay {
        self.fk_skeletonOverlay = nil
      }
      completion?()
    }
  }
}

// MARK: - UITableView / UICollectionView helpers

public extension UITableView {

  /// Shows skeletons on all currently visible cells (overlay on each cell’s root view).
  func fk_showSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    animated: Bool = true,
    respectsSafeArea: Bool = false,
    blocksInteraction: Bool = true
  ) {
    fk_skeletonPerformOnMain {
      for cell in self.visibleCells {
        cell.contentView.fk_showSkeleton(
          configuration: configuration,
          animated: animated,
          respectsSafeArea: respectsSafeArea,
          blocksInteraction: blocksInteraction
        )
      }
    }
  }

  func fk_hideSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    fk_skeletonPerformOnMain {
      let cells = self.visibleCells
      guard !cells.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for cell in cells {
        group.enter()
        cell.contentView.fk_hideSkeleton(animated: animated) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        completion?()
      }
    }
  }
}

public extension UICollectionView {

  func fk_showSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    animated: Bool = true,
    respectsSafeArea: Bool = false,
    blocksInteraction: Bool = true
  ) {
    fk_skeletonPerformOnMain {
      for cell in self.visibleCells {
        cell.contentView.fk_showSkeleton(
          configuration: configuration,
          animated: animated,
          respectsSafeArea: respectsSafeArea,
          blocksInteraction: blocksInteraction
        )
      }
    }
  }

  func fk_hideSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    fk_skeletonPerformOnMain {
      let cells = self.visibleCells
      guard !cells.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for cell in cells {
        group.enter()
        cell.contentView.fk_hideSkeleton(animated: animated) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        completion?()
      }
    }
  }
}

// MARK: - Main-thread helper

private func fk_skeletonPerformOnMain(_ work: @escaping () -> Void) {
  if Thread.isMainThread {
    work()
  } else {
    DispatchQueue.main.async(execute: work)
  }
}
