import Foundation

public extension Error {
  /// Underlying `NSError` domain when bridged.
  var fk_nsErrorDomain: String {
    (self as NSError).domain
  }

  /// Underlying `NSError` code when bridged.
  var fk_nsErrorCode: Int {
    (self as NSError).code
  }

  /// `userInfo` dictionary when bridged to `NSError`.
  var fk_nsErrorUserInfo: [String: Any] {
    (self as NSError).userInfo
  }
}
