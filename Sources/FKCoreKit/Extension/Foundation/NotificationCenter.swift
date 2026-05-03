import Foundation

public extension NotificationCenter {
  /// Posts `notification` asynchronously on the main queue.
  func fk_postOnMain(_ notification: Notification) {
    if Thread.isMainThread {
      post(notification)
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.post(notification)
      }
    }
  }

  /// Convenience wrapper to post by name on the main queue.
  func fk_postOnMain(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
    fk_postOnMain(Notification(name: name, object: object, userInfo: userInfo))
  }
}
