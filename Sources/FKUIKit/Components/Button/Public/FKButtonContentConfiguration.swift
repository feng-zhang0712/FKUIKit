import UIKit

/// Layout shape for `FKButton` (`textOnly`, `imageOnly`, `textAndImage`, `custom`).
public struct FKButtonContentConfiguration: Equatable, Sendable {
  /// Describes the primary composition mode.
  public enum Kind: Equatable, Sendable {
    case textOnly
    case imageOnly
    case textAndImage(ImagePlacement)
    case custom
  }

  /// Image placement semantics for `.textAndImage`.
  public enum ImagePlacement: Equatable, Sendable {
    case leading
    case trailing
    case bothSides
  }

  /// Current content kind.
  public let kind: Kind

  /// Creates a content configuration.
  public init(kind: Kind = .textOnly) {
    self.kind = kind
  }

  /// Text-only preset.
  public static let textOnly = FKButtonContentConfiguration(kind: .textOnly)
  /// Image-only preset.
  public static let imageOnly = FKButtonContentConfiguration(kind: .imageOnly)
  /// Custom-content-only preset.
  public static let custom = FKButtonContentConfiguration(kind: .custom)

  /// Text and image factory.
  public static func textAndImage(_ placement: ImagePlacement) -> FKButtonContentConfiguration {
    FKButtonContentConfiguration(kind: .textAndImage(placement))
  }

  /// Default content preset.
  public static let `default` = FKButtonContentConfiguration()
}
