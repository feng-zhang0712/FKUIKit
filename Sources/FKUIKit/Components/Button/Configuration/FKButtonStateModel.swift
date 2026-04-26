import UIKit

/// Describes the full visual/content model for a single `UIControl.State` registration.
///
/// Use this when you want to configure a button state in one place (appearance + labels + images + custom content).
public struct FKButtonStateModel {
  /// Optional container appearance for this state.
  public var appearance: FKButtonAppearance?
  /// Optional title configuration for this state.
  public var title: FKButtonLabelConfiguration?
  /// Optional subtitle configuration for this state.
  public var subtitle: FKButtonLabelConfiguration?
  /// Optional image configurations by slot for this state.
  public var images: [FKButton.ImageSlot: FKButtonImageConfiguration]?
  /// Optional custom-content configuration for this state.
  public var customContent: FKButtonCustomContentConfiguration?

  /// Creates a state model.
  public init(
    appearance: FKButtonAppearance? = nil,
    title: FKButtonLabelConfiguration? = nil,
    subtitle: FKButtonLabelConfiguration? = nil,
    images: [FKButton.ImageSlot: FKButtonImageConfiguration]? = nil,
    customContent: FKButtonCustomContentConfiguration? = nil
  ) {
    self.appearance = appearance
    self.title = title
    self.subtitle = subtitle
    self.images = images
    self.customContent = customContent
  }
}

