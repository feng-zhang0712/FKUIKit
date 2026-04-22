import ObjectiveC
import UIKit

private enum FKSwipeTableAssociationKey {
  nonisolated(unsafe) static var manager: UInt8 = 0
  nonisolated(unsafe) static var provider: UInt8 = 0
}

private final class FKSwipeActionProviderBox {
  let provider: (IndexPath) -> FKSwipeActionConfiguration
  init(provider: @escaping (IndexPath) -> FKSwipeActionConfiguration) {
    self.provider = provider
  }
}

public extension UITableView {
  /// Enables FKSwipeAction with one line, without subclassing or modifying any cells.
  ///
  /// - Parameters:
  ///   - configuration: Optional per-list baseline configuration. When `nil`, the manager starts from
  ///     `FKSwipeActionManager.globalDefaultConfiguration`.
  ///   - provider: Per-row configuration provider. Called with the current `IndexPath` to supply
  ///     left/right action buttons and interaction options.
  ///
  /// - Important: iOS 13.0+ only. This API is designed to be **non-invasive**:
  ///   it does not require cell subclassing and does not modify your data source/delegate.
  ///
  /// - Note: Safe to call from any thread; UI work is always scheduled onto the main thread.
  func fk_enableSwipeActions(
    configuration: FKSwipeActionConfiguration? = nil,
    provider: @escaping (IndexPath) -> FKSwipeActionConfiguration
  ) {
    runOnMain { [weak self] in
      guard let self else { return }
      let manager = self.fk_swipeActionManager
      if let configuration {
        manager.apply(configuration: configuration)
      }
      objc_setAssociatedObject(
        self,
        &FKSwipeTableAssociationKey.provider,
        FKSwipeActionProviderBox(provider: provider),
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      manager.setProvider { [weak self] indexPath in
        guard
          let self,
          let box = objc_getAssociatedObject(self, &FKSwipeTableAssociationKey.provider) as? FKSwipeActionProviderBox
        else {
          return FKSwipeActionConfiguration()
        }
        return box.provider(indexPath)
      }
      manager.installIfNeeded()
      manager.setEnabled(true)
    }
  }

  /// Enables/disables swipe actions dynamically.
  ///
  /// - Parameter enabled: Whether swipe actions are active.
  ///
  /// - Note: When disabling, any currently opened cell will be closed automatically.
  func fk_setSwipeActionsEnabled(_ enabled: Bool) {
    runOnMain { [weak self] in
      self?.fk_swipeActionManager.setEnabled(enabled)
    }
  }

  /// Closes any opened swipe actions immediately.
  ///
  /// - Parameter animated: Whether to animate closing.
  func fk_closeSwipeActions(animated: Bool = true) {
    runOnMain { [weak self] in
      self?.fk_swipeActionManager.closeOpenedCell(animated: animated)
    }
  }

  /// Manager instance associated with this table view.
  internal var fk_swipeActionManager: FKSwipeActionManager {
    if let cached = objc_getAssociatedObject(self, &FKSwipeTableAssociationKey.manager) as? FKSwipeActionManager {
      return cached
    }
    let manager = FKSwipeActionManager(
      scrollView: self,
      configuration: FKSwipeActionManager.globalDefaultConfiguration
    )
    objc_setAssociatedObject(self, &FKSwipeTableAssociationKey.manager, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return manager
  }

  private func runOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }
}

