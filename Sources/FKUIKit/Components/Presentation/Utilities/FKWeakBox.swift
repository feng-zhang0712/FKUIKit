import Foundation

/// Internal weak reference wrapper used by FK implementation details.
///
/// Public API should use `FKWeakReference` instead.
final class FKWeakBox<Object: AnyObject> {
  weak var object: Object?

  init(_ object: Object?) {
    self.object = object
  }
}
