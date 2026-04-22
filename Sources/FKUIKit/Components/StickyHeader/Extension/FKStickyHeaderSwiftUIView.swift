#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI bridge that enables FKStickyHeader on an underlying UIKit scroll view.
@available(iOS 13.0, *)
public struct FKStickyHeaderAdapter: UIViewRepresentable {
  /// Sticky configuration applied to the discovered scroll view.
  public var configuration: FKStickyConfiguration

  /// UIKit target provider.
  public var provider: (UIScrollView) -> [FKStickyTarget]

  /// Creates a bridge view.
  ///
  /// - Parameters:
  ///   - configuration: Sticky configuration.
  ///   - provider: Target provider closure.
  public init(
    configuration: FKStickyConfiguration = FKStickyManager.shared.templateConfiguration,
    provider: @escaping (UIScrollView) -> [FKStickyTarget]
  ) {
    self.configuration = configuration
    self.provider = provider
  }

  public func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isHidden = true
    view.isUserInteractionEnabled = false
    return view
  }

  public func updateUIView(_ uiView: UIView, context: Context) {
    guard let scrollView = uiView.fk_findSuperview(of: UIScrollView.self) else { return }
    scrollView.fk_enableStickyHeaders(configuration: configuration, provider: provider)
  }
}

@available(iOS 13.0, *)
public extension View {
  /// Enables FKStickyHeader in SwiftUI `List`/`ScrollView`.
  ///
  /// - Parameters:
  ///   - configuration: Sticky configuration for this list.
  ///   - provider: UIKit target provider for discovered scroll view.
  /// - Returns: Decorated view.
  func fk_stickyHeader(
    configuration: FKStickyConfiguration = FKStickyManager.shared.templateConfiguration,
    provider: @escaping (UIScrollView) -> [FKStickyTarget]
  ) -> some View {
    background(
      FKStickyHeaderAdapter(configuration: configuration, provider: provider)
        .frame(width: 0, height: 0)
    )
  }
}

private extension UIView {
  func fk_findSuperview<T: UIView>(of type: T.Type) -> T? {
    var cursor = superview
    while let current = cursor {
      if let hit = current as? T {
        return hit
      }
      cursor = current.superview
    }
    return nil
  }
}
#endif
