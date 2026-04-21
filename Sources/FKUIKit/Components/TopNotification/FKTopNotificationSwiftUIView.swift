import UIKit

#if canImport(SwiftUI)
import SwiftUI

public extension FKTopNotification {
  /// Shows a custom SwiftUI view as notification content.
  ///
  /// - Parameters:
  ///   - content: SwiftUI content view.
  ///   - configuration: Per-message configuration.
  ///   - onTap: Called when user taps notification body.
  ///   - onAction: Called when user taps trailing action.
  /// - Returns: A handle that can dismiss this request.
  ///
  /// - Note: The SwiftUI content is hosted with `UIHostingController` and rendered in the global
  ///   top window, consistent with UIKit calls.
  @MainActor
  @discardableResult
  static func show<Content: View>(
    swiftUIView content: Content,
    configuration: FKTopNotificationConfiguration? = nil,
    onTap: (() -> Void)? = nil,
    onAction: (() -> Void)? = nil
  ) -> FKTopNotificationHandle {
    let host = UIHostingController(rootView: content)
    host.view.backgroundColor = .clear
    return show(
      customView: host.view,
      configuration: configuration,
      onTap: onTap,
      onAction: onAction
    )
  }
}
#endif
