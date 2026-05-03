import UIKit

/// Bundles appearance, labels, images, and custom content for one **exact** `UIControl.State` key.
///
/// Pass this to `FKButton.setModel(_:for:)`. For a non-`nil` model, omitted properties leave existing registrations untouched.
/// Pass `nil` for the whole model to clear every registration for that state (see `FKButton.setModel` documentation).
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

