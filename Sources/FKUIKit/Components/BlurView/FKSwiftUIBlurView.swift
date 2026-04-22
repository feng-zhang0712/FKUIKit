import UIKit

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI adapter for `FKBlurView`.
///
/// - Important: For best dynamic performance in SwiftUI, prefer `.system(...)` backend.
public struct FKSwiftUIBlurView: UIViewRepresentable {
  /// Blur configuration.
  public var configuration: FKBlurConfiguration

  /// Creates a SwiftUI blur view.
  ///
  /// - Parameter configuration: Blur configuration.
  public init(configuration: FKBlurConfiguration = FKBlurGlobalDefaults.configuration) {
    self.configuration = configuration
  }

  /// Creates and configures the underlying UIKit view.
  ///
  /// - Parameter context: A context structure containing information about the current state of the system.
  /// - Returns: A configured `FKBlurView` instance.
  public func makeUIView(context: Context) -> FKBlurView {
    let view = FKBlurView()
    view.configuration = configuration
    return view
  }

  /// Updates the underlying UIKit view when SwiftUI state changes.
  ///
  /// - Parameters:
  ///   - uiView: The `FKBlurView` instance previously created by `makeUIView(context:)`.
  ///   - context: A context structure containing information about the current state of the system.
  public func updateUIView(_ uiView: FKBlurView, context: Context) {
    uiView.configuration = configuration
  }
}
#endif

