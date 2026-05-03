import Foundation

/// A weak reference wrapper intended for public API surfaces.
///
/// Use this when an FK configuration needs to point at an object (for example, a source view
/// or a tracked scroll view) without extending its lifetime.
public final class FKWeakReference<Object: AnyObject> {
  /// The referenced object, if still alive.
  public weak var object: Object?

  /// Creates a weak reference wrapper.
  public init(_ object: Object?) {
    self.object = object
  }
}

