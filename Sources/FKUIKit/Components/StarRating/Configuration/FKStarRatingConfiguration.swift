//
// FKStarRatingConfiguration.swift
//
// Configuration payload for FKStarRating.
//

import UIKit

/// Full configuration model for one `FKStarRating` instance.
public struct FKStarRatingConfiguration {
  /// Rating mode used for user interaction snapping.
  public var mode: FKStarRatingMode
  /// Number of stars to display. Effective range is `1...10`.
  public var starCount: Int
  /// Size for each star item.
  public var starSize: CGSize
  /// Horizontal spacing between stars.
  public var starSpacing: CGFloat
  /// Whether rating interaction is enabled.
  public var isEditable: Bool
  /// Lower rating bound for clamping.
  public var minimumRating: CGFloat
  /// Upper rating bound for clamping.
  public var maximumRating: CGFloat
  /// Rendering strategy for stars.
  public var renderMode: FKStarRatingRenderMode
  /// Image used for filled stars.
  public var selectedImage: UIImage?
  /// Image used for empty stars.
  public var unselectedImage: UIImage?
  /// Optional image used specifically for half stars.
  public var halfImage: UIImage?
  /// Tint color for selected stars in `.color` mode.
  public var selectedColor: UIColor
  /// Tint color for unselected stars in `.color` mode.
  public var unselectedColor: UIColor
  /// Visual decoration style for each star slot.
  public var starStyle: FKStarRatingStarStyle
  /// Whether pan gesture should update rating continuously.
  public var allowsContinuousPan: Bool

  /// Creates a full configuration payload.
  public init(
    mode: FKStarRatingMode = .half,
    starCount: Int = 5,
    starSize: CGSize = CGSize(width: 24, height: 24),
    starSpacing: CGFloat = 8,
    isEditable: Bool = true,
    minimumRating: CGFloat = 0,
    maximumRating: CGFloat? = nil,
    renderMode: FKStarRatingRenderMode = .color,
    selectedImage: UIImage? = nil,
    unselectedImage: UIImage? = nil,
    halfImage: UIImage? = nil,
    selectedColor: UIColor = .systemYellow,
    unselectedColor: UIColor = .systemGray3,
    starStyle: FKStarRatingStarStyle = .plain,
    allowsContinuousPan: Bool = true
  ) {
    self.mode = mode
    self.starCount = max(1, min(10, starCount))
    self.starSize = CGSize(width: max(1, starSize.width), height: max(1, starSize.height))
    self.starSpacing = max(0, starSpacing)
    self.isEditable = isEditable
    self.minimumRating = max(0, minimumRating)
    self.maximumRating = min(CGFloat(self.starCount), max(self.minimumRating, maximumRating ?? CGFloat(self.starCount)))
    self.renderMode = renderMode
    self.selectedImage = selectedImage
    self.unselectedImage = unselectedImage
    self.halfImage = halfImage
    self.selectedColor = selectedColor
    self.unselectedColor = unselectedColor
    self.starStyle = starStyle
    self.allowsContinuousPan = allowsContinuousPan
  }

  /// Builder helper for one-line setup.
  public static func build(_ updates: (inout FKStarRatingConfiguration) -> Void) -> FKStarRatingConfiguration {
    var configuration = FKStarRatingConfiguration()
    updates(&configuration)
    return configuration
  }
}
