import ObjectiveC.runtime
import UIKit

private enum FKSkeletonAssociatedKeys {
  nonisolated(unsafe) static var overlayView: UInt8 = 0
  nonisolated(unsafe) static var shape: UInt8 = 0
  nonisolated(unsafe) static var excluded: UInt8 = 0
  nonisolated(unsafe) static var configOverride: UInt8 = 0
  nonisolated(unsafe) static var loadingToken: UInt8 = 0
}

// MARK: - UIView

public extension UIView {

  /// Pins a ``FKSkeletonView`` overlay above existing content (does not swap subviews).
  func fk_showSkeleton(
    configuration: FKSkeletonConfiguration? = nil,
    animated: Bool = true,
    respectsSafeArea: Bool = false,
    blocksInteraction: Bool = true
  ) {
    FKSkeletonDispatch.runOnMain {
      self.fk_showSkeletonOnMainThread(
        configuration: configuration,
        animated: animated,
        respectsSafeArea: respectsSafeArea,
        blocksInteraction: blocksInteraction
      )
    }
  }

  /// Removes the overlay installed by ``fk_showSkeleton(configuration:animated:respectsSafeArea:blocksInteraction:)``.
  func fk_hideSkeleton(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonDispatch.runOnMain {
      self.fk_hideSkeletonOnMainThread(animated: animated, completion: completion)
    }
  }

  /// `true` while an overlay reference is still attached (even mid-fade).
  var fk_isShowingSkeleton: Bool {
    fk_skeletonOverlay != nil
  }

  /// Replaces the inherited configuration for placeholders generated on this view subtree.
  var fk_skeletonConfigurationOverride: FKSkeletonConfiguration? {
    get { objc_getAssociatedObject(self, &FKSkeletonAssociatedKeys.configOverride) as? FKSkeletonConfiguration }
    set { objc_setAssociatedObject(self, &FKSkeletonAssociatedKeys.configOverride, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Controls placeholder corner geometry during auto generation.
  var fk_skeletonShape: FKSkeletonShape? {
    get { objc_getAssociatedObject(self, &FKSkeletonAssociatedKeys.shape) as? FKSkeletonShape }
    set { objc_setAssociatedObject(self, &FKSkeletonAssociatedKeys.shape, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Skips this view when recursively generating placeholders.
  var fk_isSkeletonExcluded: Bool {
    get { (objc_getAssociatedObject(self, &FKSkeletonAssociatedKeys.excluded) as? NSNumber)?.boolValue ?? false }
    set { objc_setAssociatedObject(self, &FKSkeletonAssociatedKeys.excluded, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Generates placeholders by scanning supported leaf views (labels, images, stacks, etc.).
  func fk_showAutoSkeleton(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    FKSkeletonManager.shared.show(on: self, configuration: configuration, options: options, animated: animated)
  }

  /// Removes placeholders created through ``fk_showAutoSkeleton(configuration:options:animated:)``.
  func fk_hideAutoSkeleton(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonManager.shared.hide(on: self, animated: animated, completion: completion)
  }

  /// Convenience wrapper around show/hide for boolean loading flags.
  func fk_setSkeletonLoading(
    _ isLoading: Bool,
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    if isLoading {
      FKSkeletonManager.shared.show(on: self, configuration: configuration, options: options, animated: animated)
    } else {
      FKSkeletonManager.shared.hide(on: self, animated: animated, completion: nil)
    }
  }

  /// Shows auto placeholders then hides them only when `done()` matches the latest token.
  func fk_withSkeletonLoading(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true,
    loadingAction: @escaping (@escaping () -> Void) -> Void
  ) {
    FKSkeletonDispatch.runOnMain {
      let token = UUID().uuidString
      objc_setAssociatedObject(self, &FKSkeletonAssociatedKeys.loadingToken, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      FKSkeletonManager.shared.show(on: self, configuration: configuration, options: options, animated: animated)
      loadingAction { [weak self] in
        FKSkeletonDispatch.runOnMain {
          guard let view = self else { return }
          let current = objc_getAssociatedObject(view, &FKSkeletonAssociatedKeys.loadingToken) as? String
          guard current == token else { return }
          FKSkeletonManager.shared.hide(on: view, animated: animated, completion: nil)
        }
      }
    }
  }

  fileprivate var fk_skeletonOverlay: FKSkeletonView? {
    get { objc_getAssociatedObject(self, &FKSkeletonAssociatedKeys.overlayView) as? FKSkeletonView }
    set { objc_setAssociatedObject(self, &FKSkeletonAssociatedKeys.overlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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

// MARK: - UITableView

public extension UITableView {

  func fk_showSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    animated: Bool = true,
    respectsSafeArea: Bool = false,
    blocksInteraction: Bool = true
  ) {
    FKSkeletonDispatch.runOnMain {
      for host in FKSkeletonVisibleCells.contentRoots(from: self.visibleCells) {
        host.fk_showSkeleton(
          configuration: configuration,
          animated: animated,
          respectsSafeArea: respectsSafeArea,
          blocksInteraction: blocksInteraction
        )
      }
    }
  }

  func fk_hideSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonDispatch.runOnMain {
      let hosts = FKSkeletonVisibleCells.contentRoots(from: self.visibleCells)
      guard !hosts.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for host in hosts {
        group.enter()
        host.fk_hideSkeleton(animated: animated) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        completion?()
      }
    }
  }

  func fk_showAutoSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    FKSkeletonDispatch.runOnMain {
      for host in FKSkeletonVisibleCells.contentRoots(from: self.visibleCells) {
        host.fk_showAutoSkeleton(configuration: configuration, options: options, animated: animated)
      }
    }
  }

  func fk_hideAutoSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonDispatch.runOnMain {
      let hosts = FKSkeletonVisibleCells.contentRoots(from: self.visibleCells)
      guard !hosts.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for host in hosts {
        group.enter()
        host.fk_hideAutoSkeleton(animated: animated) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        completion?()
      }
    }
  }
}

// MARK: - UICollectionView

public extension UICollectionView {

  func fk_showSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    animated: Bool = true,
    respectsSafeArea: Bool = false,
    blocksInteraction: Bool = true
  ) {
    FKSkeletonDispatch.runOnMain {
      for host in FKSkeletonVisibleCells.contentRoots(from: self.visibleCells) {
        host.fk_showSkeleton(
          configuration: configuration,
          animated: animated,
          respectsSafeArea: respectsSafeArea,
          blocksInteraction: blocksInteraction
        )
      }
    }
  }

  func fk_hideSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonDispatch.runOnMain {
      let hosts = FKSkeletonVisibleCells.contentRoots(from: self.visibleCells)
      guard !hosts.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for host in hosts {
        group.enter()
        host.fk_hideSkeleton(animated: animated) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        completion?()
      }
    }
  }

  func fk_showAutoSkeletonOnVisibleCells(
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    FKSkeletonDispatch.runOnMain {
      for host in FKSkeletonVisibleCells.contentRoots(from: self.visibleCells) {
        host.fk_showAutoSkeleton(configuration: configuration, options: options, animated: animated)
      }
    }
  }

  func fk_hideAutoSkeletonOnVisibleCells(animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonDispatch.runOnMain {
      let hosts = FKSkeletonVisibleCells.contentRoots(from: self.visibleCells)
      guard !hosts.isEmpty else {
        completion?()
        return
      }
      let group = DispatchGroup()
      for host in hosts {
        group.enter()
        host.fk_hideAutoSkeleton(animated: animated) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        completion?()
      }
    }
  }
}
