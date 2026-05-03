#if canImport(UIKit)
import UIKit

public extension UIApplication {
  /// Opens the app's Settings page on `shared` when possible.
  static func fk_openAppSettings() {
    guard let url = URL(string: Self.openSettingsURLString) else { return }
    shared.open(url, options: [:], completionHandler: nil)
  }

  /// The key window from the first connected `UIWindowScene`, when available.
  var fk_keyWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
  }

  /// Safe area inset from the key window's root view controller, or `.zero`.
  var fk_keyWindowSafeAreaInsets: UIEdgeInsets {
    fk_keyWindow?.safeAreaInsets ?? .zero
  }
}

#endif
