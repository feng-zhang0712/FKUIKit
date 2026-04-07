//
//  FKButton+Content.swift
//
// Main content layout for `FKButton` (text only, image only, text+image, custom view) and image/text placement.
//

public extension FKButton {
  /// Main content layout strategy; combined with `axis` and state APIs to produce the final UI.
  struct Content {

    /// Controls the main content type.
    ///
    /// - `textOnly`: show title (subtitle is part of the title area).
    /// - `imageOnly`: show images only, no title/subtitle.
    /// - `textAndImage`: show title and images; relative placement is determined by `ImagePlacement` and affected by `FKButton.axis`.
    /// - `custom`: main content comes entirely from `CustomContent.view` (no built-in title/image slots).
    public enum Kind: Equatable {
      case textOnly
      case imageOnly
      case textAndImage(ImagePlacement)
      case custom
    }
    
    /// Image placement semantics for `.textAndImage`.
    ///
    /// - `leading`: image on the leading side relative to the title.
    /// - `trailing`: image on the trailing side relative to the title.
    /// - `bothSides`: images on both leading and trailing sides (left/right or top/bottom depending on `axis`).
    public enum ImagePlacement {
      case leading
      case trailing
      case bothSides
    }
    
    public let kind: Kind

    public init(kind: Kind = .textOnly) {
      self.kind = kind
    }
    
    public nonisolated(unsafe) static let `default` = Content()
  }
}
