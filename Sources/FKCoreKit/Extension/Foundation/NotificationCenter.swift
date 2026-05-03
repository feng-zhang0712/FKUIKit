import Foundation

/// Boxes a `Notification` so it can cross a `@Sendable` `DispatchQueue.main.async` boundary.
/// Posting still occurs on the main thread only; callers must not mutate `object` / `userInfo` concurrently until posted.
private final class FKNotificationPostBox: @unchecked Sendable {
  let notification: Notification
  init(_ notification: Notification) {
    self.notification = notification
  }
}

public extension NotificationCenter {
  /// Posts `notification` asynchronously on the main queue.
  func fk_postOnMain(_ notification: Notification) {
    if Thread.isMainThread {
      post(notification)
    } else {
      let box = FKNotificationPostBox(notification)
      DispatchQueue.main.async { [weak self] in
        self?.post(box.notification)
      }
    }
  }

  /// Convenience wrapper to post by name on the main queue.
  func fk_postOnMain(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
    fk_postOnMain(Notification(name: name, object: object, userInfo: userInfo))
  }
}
