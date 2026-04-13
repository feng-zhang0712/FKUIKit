//
//  FKButton+Content.swift
//
// Main content layout for `FKButton` (text only, image only, text+image, custom view) and image/text placement.
//

public extension FKButton {
  /// Main content layout strategy; combined with `axis` and state APIs to produce the final UI.
  struct Content: Equatable, Sendable {

    /// Controls the main content type.
    ///
    /// - `textOnly`: show title (subtitle is part of the title area).
    /// - `imageOnly`: show images only, no title/subtitle.
    /// - `textAndImage`: show title and images; relative placement is determined by `ImagePlacement` and affected by `FKButton.axis`.
    /// - `custom`: main content comes entirely from `CustomContent.view` (no built-in title/image slots).
    public enum Kind: Equatable, Sendable {
      case textOnly
      case imageOnly
      case textAndImage(ImagePlacement)
      case custom
    }
    
    /// Image placement semantics for `.textAndImage`.
    ///
    /// - `leading`: image on the leading side relative to the title.
    /// - `trailing`: image on the trailing side relative to the title.
    /// - `bothSides`: images on both leading and trailing sides.
    ///
    /// Final physical direction is resolved with `FKButton.axis`.
    public enum ImagePlacement: Equatable, Sendable {
      case leading
      case trailing
      case bothSides
    }
    
    public let kind: Kind

    public init(kind: Kind = .textOnly) {
      self.kind = kind
    }

    /// Convenient preset for text-only content.
    public nonisolated(unsafe) static let textOnly = Content(kind: .textOnly)
    /// Convenient preset for image-only content.
    public nonisolated(unsafe) static let imageOnly = Content(kind: .imageOnly)
    /// Convenient preset for custom content-only mode.
    public nonisolated(unsafe) static let custom = Content(kind: .custom)
    /// Convenient factory for text-and-image composition.
    public static func textAndImage(_ placement: ImagePlacement) -> Content {
      Content(kind: .textAndImage(placement))
    }
    
    public nonisolated(unsafe) static let `default` = Content()
  }
}
