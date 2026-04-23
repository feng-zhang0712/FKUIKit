import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Content payload for one overlay request.
public enum FKToastContent: @unchecked Sendable {
  /// A plain text message.
  case message(String)
  /// A two-line hierarchy for richer status communication.
  case titleSubtitle(title: String, subtitle: String)
  /// A UIKit view provider evaluated on the main actor at render time.
  case customView(@MainActor () -> UIView)
}

/// Builder used by advanced APIs for high readability.
public struct FKToastBuilder: Sendable {
  /// Overlay content.
  public var content: FKToastContent
  /// Optional icon override.
  public var icon: UIImage?
  /// Full per-request configuration.
  public var configuration: FKToastConfiguration
  /// Show and dismiss callbacks.
  public var hooks: FKToastLifecycleHooks
  /// Primary action callback.
  public var actionHandler: (@MainActor () -> Void)?
  /// Secondary action callback.
  public var secondaryActionHandler: (@MainActor () -> Void)?

  /// Creates a request builder.
  ///
  /// - Parameters:
  ///   - content: Overlay payload.
  ///   - icon: Optional explicit icon.
  ///   - configuration: Per-request display options.
  ///   - hooks: Lifecycle callbacks.
  ///   - actionHandler: Primary action callback.
  ///   - secondaryActionHandler: Secondary action callback.
  public init(
    content: FKToastContent,
    icon: UIImage? = nil,
    configuration: FKToastConfiguration = .init(),
    hooks: FKToastLifecycleHooks = .init(),
    actionHandler: (@MainActor () -> Void)? = nil,
    secondaryActionHandler: (@MainActor () -> Void)? = nil
  ) {
    self.content = content
    self.icon = icon
    self.configuration = configuration
    self.hooks = hooks
    self.actionHandler = actionHandler
    self.secondaryActionHandler = secondaryActionHandler
  }

  /// Returns a copy configured as a HUD request.
  ///
  /// - Parameters:
  ///   - interceptTouches: Whether to block background interactions.
  ///   - timeout: Safety timeout to auto-dismiss hanging HUDs.
  /// - Returns: A modified builder ready for HUD presentation.
  public func asHUD(interceptTouches: Bool = true, timeout: TimeInterval? = 25) -> Self {
    var copied = self
    copied.configuration.kind = .hud
    copied.configuration.interceptTouches = interceptTouches
    copied.configuration.timeout = timeout
    copied.configuration.duration = timeout ?? 0
    return copied
  }
}

#if canImport(SwiftUI)
public extension FKToastBuilder {
  /// Wraps a SwiftUI view into UIKit so the presenter stays UIKit-native and stable.
  @MainActor
  static func swiftUIView<Content: View>(
    _ view: Content,
    configuration: FKToastConfiguration = .init()
  ) -> FKToastBuilder {
    .init(content: .customView {
      let host = UIHostingController(rootView: view)
      host.view.backgroundColor = .clear
      return host.view
    }, configuration: configuration)
  }
}
#endif
