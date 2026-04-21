import Foundation

/// Disposable token used to stop an observation created by FKBusinessKit.
public final class FKBusinessObservationToken: @unchecked Sendable {
  /// Lock protecting cancel closure access.
  private let lock = NSLock()

  /// Stored cancellation callback executed on invalidation.
  private var cancelClosure: (() -> Void)?

  /// Creates a token with a cancellation callback.
  ///
  /// - Parameter cancelClosure: Callback executed when invalidated or deinitialized.
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

