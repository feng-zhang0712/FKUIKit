#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI bridge that enables FKSwipeAction on an underlying UIKit list.
///
/// This adapter is intentionally non-invasive: it does not require any third-party introspection
/// libraries. It simply probes the superview hierarchy to find a backing `UITableView` or
/// `UICollectionView` (as commonly used by SwiftUI `List` on iOS 13+), and then enables FKSwipeAction.
///
/// - Important: SwiftUI internal implementations may change across iOS versions. This adapter
///   works best when the underlying list is backed by UIKit list views.
@available(iOS 13.0, *)
public struct FKSwipeActionAdapter: UIViewRepresentable {
  /// Baseline configuration applied to the discovered list.
  public var configuration: FKSwipeActionConfiguration

  /// Per-indexPath configuration provider.
  ///
  /// This closure is called when a swipe begins to resolve action buttons and behavior
  /// for the current row/item.
  public var provider: (IndexPath) -> FKSwipeActionConfiguration

  /// Creates a bridge view.
  ///
  /// - Parameters:
  ///   - configuration: Baseline configuration for the list.
  ///   - provider: Per-indexPath configuration provider.
  ///
  /// - Note: The returned view is a hidden background probe and does not affect layout.
  public init(
    configuration: FKSwipeActionConfiguration = FKSwipeActionManager.globalDefaultConfiguration,
    provider: @escaping (IndexPath) -> FKSwipeActionConfiguration
  ) {
    self.configuration = configuration
    self.provider = provider
  }

  /// Creates the underlying UIKit view used as an invisible probe.
  ///
  /// - Parameter context: The SwiftUI context.
  /// - Returns: A hidden, non-interactive `UIView` attached to the view hierarchy.
  public func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isHidden = true
    view.isUserInteractionEnabled = false
    return view
  }

  /// Updates the probe view and enables FKSwipeAction on the discovered UIKit list.
  ///
  /// - Parameters:
  ///   - uiView: The probe view created by `makeUIView(context:)`.
  ///   - context: The SwiftUI context.
  ///
  /// - Note: This method is called by SwiftUI multiple times during view updates.
  ///   The adapter is idempotent: enabling swipe actions repeatedly is safe.
  public func updateUIView(_ uiView: UIView, context: Context) {
    // In SwiftUI, `List` is commonly backed by UITableView on iOS 13-15, and by UICollectionView
    // on newer system versions depending on implementation. We probe superviews non-invasively.
    if let table = uiView.fk_findSuperview(of: UITableView.self) {
      table.fk_enableSwipeActions(configuration: configuration, provider: provider)
      return
    }
    if let collection = uiView.fk_findSuperview(of: UICollectionView.self) {
      collection.fk_enableSwipeActions(configuration: configuration, provider: provider)
      return
    }
  }
}

@available(iOS 13.0, *)
public extension View {
  /// Enables FKSwipeAction in SwiftUI `List`/`ScrollView` that is backed by UIKit list views.
  ///
  /// - Parameters:
  ///   - configuration: Baseline configuration for the list.
  ///   - provider: Per-indexPath configuration provider.
  /// - Returns: Decorated view.
  ///
  /// ## Example
  /// ```swift
  /// List(items) { item in
  ///   Text(item.title)
  /// }
  /// .fk_swipeAction { indexPath in
  ///   FKSwipeActionConfiguration(
  ///     rightActions: [
  ///       FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed)) { }
  ///     ]
  ///   )
  /// }
  /// ```
  func fk_swipeAction(
    configuration: FKSwipeActionConfiguration = FKSwipeActionManager.globalDefaultConfiguration,
    provider: @escaping (IndexPath) -> FKSwipeActionConfiguration
  ) -> some View {
    background(
      FKSwipeActionAdapter(configuration: configuration, provider: provider)
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

