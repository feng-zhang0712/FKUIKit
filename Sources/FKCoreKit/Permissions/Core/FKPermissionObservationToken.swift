import Foundation

/// Disposable token used to stop permission status observation.
public final class FKPermissionObservationToken: @unchecked Sendable {
  private let lock = NSLock()
  private var cancelClosure: (() -> Void)?

  init(cancelClosure: @escaping () -> Void) {
    self.cancelClosure = cancelClosure
  }

  deinit {
    invalidate()
  }

  /// Stops observation associated with this token.
  public func invalidate() {
    lock.lock()
    let cancel = cancelClosure
    cancelClosure = nil
    lock.unlock()
    cancel?()
  }
}
