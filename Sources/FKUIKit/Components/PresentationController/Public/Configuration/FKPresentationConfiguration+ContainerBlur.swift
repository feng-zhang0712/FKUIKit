import UIKit

public extension FKPresentationConfiguration {
  /// Blur material applied to the presented container itself (not the backdrop mask).
  struct ContainerBlurConfiguration {
    /// Enables container blur.
    public var isEnabled: Bool
    /// Material configuration reused from FKBlurView.
    public var configuration: FKBlurConfiguration

    /// Creates container blur behavior.
    public init(
      isEnabled: Bool = false,
      configuration: FKBlurConfiguration = .init(backend: .system(style: .systemMaterial))
    ) {
      self.isEnabled = isEnabled
      self.configuration = configuration
    }
  }
}

