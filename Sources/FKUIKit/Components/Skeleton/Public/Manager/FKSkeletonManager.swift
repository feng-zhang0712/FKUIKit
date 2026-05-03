import Foundation
import UIKit

/// Explicit entry point for auto skeleton lifetime (``UIView/fk_showAutoSkeleton`` forwards here).
///
/// Calls are marshaled onto the main queue; the type is `@unchecked Sendable` so you may reference
/// `shared` from background isolation contexts when needed.
public final class FKSkeletonManager: @unchecked Sendable {
  public static let shared = FKSkeletonManager()

  private let lock = NSLock()
  private let controllerTable = NSMapTable<UIView, FKSkeletonController>(keyOptions: .weakMemory, valueOptions: .strongMemory)

  private init() {}

  public func show(
    on view: UIView,
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    FKSkeletonDispatch.runOnMain {
      let controller = self.controller(for: view)
      controller.showSkeleton(configuration: configuration, options: options, animated: animated)
    }
  }

  public func hide(on view: UIView, animated: Bool = true, completion: (() -> Void)? = nil) {
    FKSkeletonDispatch.runOnMain {
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
