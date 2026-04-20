//
// FKSkeletonManager.swift
//

import Foundation
import UIKit

/// Central manager for view-tree based skeleton lifecycle.
///
/// `@unchecked Sendable` is used because internal state is protected by a lock and
/// skeleton rendering is marshaled to the main thread.
public final class FKSkeletonManager: @unchecked Sendable {
  public static let shared = FKSkeletonManager()

  private let lock = NSLock()
  private let controllerTable = NSMapTable<UIView, FKSkeletonController>(keyOptions: .weakMemory, valueOptions: .strongMemory)

  private init() {}

  /// Shows generated skeleton placeholders for the provided host view.
  public func show(
    on view: UIView,
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    performOnMain {
      let controller = self.controller(for: view)
      controller.showSkeleton(configuration: configuration, options: options, animated: animated)
    }
  }

  /// Hides generated skeleton placeholders for the provided host view.
  public func hide(on view: UIView, animated: Bool = true, completion: (() -> Void)? = nil) {
    performOnMain {
      guard let controller = self.controllerTable.object(forKey: view) else {
        completion?()
        return
      }
      controller.hideSkeleton(animated: animated, completion: completion)
    }
  }

  private func controller(for view: UIView) -> FKSkeletonController {
    lock.lock()
    defer { lock.unlock() }
    if let controller = controllerTable.object(forKey: view) {
      return controller
    }
    let created = FKSkeletonController(hostView: view)
    controllerTable.setObject(created, forKey: view)
    return created
  }
}

private func performOnMain(_ work: @escaping () -> Void) {
  if Thread.isMainThread {
    work()
  } else {
    DispatchQueue.main.async(execute: work)
  }
}
