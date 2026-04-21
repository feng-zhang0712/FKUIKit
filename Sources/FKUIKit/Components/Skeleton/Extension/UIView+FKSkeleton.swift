//
// UIView+FKSkeleton.swift
//

import ObjectiveC.runtime
import UIKit

// MARK: - Associated object keys

private enum FKSkeletonKeys {
  nonisolated(unsafe) static var overlayView: UInt8 = 0
  nonisolated(unsafe) static var shape: UInt8 = 0
  nonisolated(unsafe) static var excluded: UInt8 = 0
  nonisolated(unsafe) static var configOverride: UInt8 = 0
  nonisolated(unsafe) static var loadingToken: UInt8 = 0
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

  /// Optional per-view configuration override used by tree-based skeleton generation.
  var fk_skeletonConfigurationOverride: FKSkeletonConfiguration? {
    get { objc_getAssociatedObject(self, &FKSkeletonKeys.configOverride) as? FKSkeletonConfiguration }
    set { objc_setAssociatedObject(self, &FKSkeletonKeys.configOverride, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Optional per-view shape override for generated skeleton placeholders.
  var fk_skeletonShape: FKSkeletonShape? {
    get { objc_getAssociatedObject(self, &FKSkeletonKeys.shape) as? FKSkeletonShape }
    set { objc_setAssociatedObject(self, &FKSkeletonKeys.shape, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Marks this view as excluded from tree-based skeleton generation.
  var fk_isSkeletonExcluded: Bool {
    get { (objc_getAssociatedObject(self, &FKSkeletonKeys.excluded) as? NSNumber)?.boolValue ?? false }
    set { objc_setAssociatedObject(self, &FKSkeletonKeys.excluded, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Shows skeletons by scanning the current view tree and generating placeholders automatically.
  func fk_showAutoSkeleton(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    FKSkeletonManager.shared.show(on: self, configuration: configuration, options: options, animated: animated)
  }

  /// Hides skeletons created by `fk_showAutoSkeleton`.
  func fk_hideAutoSkeleton(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonManager.shared.hide(on: self, animated: animated, completion: completion)
  }

  /// Drives loading state with one line and auto-toggle skeleton visibility.
  func fk_setSkeletonLoading(
    _ isLoading: Bool,
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    if isLoading {
      fk_showAutoSkeleton(configuration: configuration, options: options, animated: animated)
    } else {
      fk_hideAutoSkeleton(animated: animated)
    }
  }

  /// Wraps an async loading action and hides skeleton only if it is still the latest request.
  func fk_withSkeletonLoading(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true,
    loadingAction: (@escaping () -> Void) -> Void
  ) {
    let token = UUID().uuidString
    objc_setAssociatedObject(self, &FKSkeletonKeys.loadingToken, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    fk_showAutoSkeleton(configuration: configuration, options: options, animated: animated)
    loadingAction { [weak self] in
      guard let self else { return }
      let current = objc_getAssociatedObject(self, &FKSkeletonKeys.loadingToken) as? String
      guard current == token else { return }
      self.fk_hideAutoSkeleton(animated: animated)
    }
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

  /// Auto-generates skeletons on every currently visible table cell.
  func fk_showAutoSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    fk_skeletonPerformOnMain {
      for cell in self.visibleCells {
        cell.contentView.fk_showAutoSkeleton(
          configuration: configuration,
          options: options,
          animated: animated
        )
      }
    }
  }

  /// Hides auto-generated skeletons on every currently visible table cell.
  func fk_hideAutoSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    fk_skeletonPerformOnMain {
      let cells = self.visibleCells
      guard !cells.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for cell in cells {
        group.enter()
        cell.contentView.fk_hideAutoSkeleton(animated: animated) {
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

  /// Auto-generates skeletons on every currently visible collection cell.
  func fk_showAutoSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    fk_skeletonPerformOnMain {
      for cell in self.visibleCells {
        cell.contentView.fk_showAutoSkeleton(
          configuration: configuration,
          options: options,
          animated: animated
        )
      }
    }
  }

  /// Hides auto-generated skeletons on every currently visible collection cell.
  func fk_hideAutoSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    fk_skeletonPerformOnMain {
      let cells = self.visibleCells
      guard !cells.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for cell in cells {
        group.enter()
        cell.contentView.fk_hideAutoSkeleton(animated: animated) {
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
