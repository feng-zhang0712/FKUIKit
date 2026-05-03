import UIKit

/// Shorter names nested under `FKButton` for call-site readability.
///
/// The canonical types remain `FKButton*` structs/enums at module scope (stable for documentation
/// and cross-module APIs). Use either style consistently within a project.
public extension FKButton {
  typealias Content = FKButtonContentConfiguration
  typealias LabelAttributes = FKButtonLabelConfiguration
  typealias ImageAttributes = FKButtonImageConfiguration
  typealias CustomContent = FKButtonCustomContentConfiguration
  typealias Appearance = FKButtonAppearance
  typealias LinearGradient = FKButtonLinearGradient
  typealias StateAppearances = FKButtonStateAppearances
  typealias AppearanceOverride = FKButtonAppearanceOverride
  typealias CornerStyle = FKButtonCornerStyle
  typealias Border = FKButtonBorderStyle
  typealias Interaction = FKButtonInteractionStyle
  typealias Shadow = FKButtonShadowStyle
  typealias ShadowPathStrategy = FKButtonShadowPathStrategy
  typealias Corner = FKButtonCorner
  typealias LoadingPresentationStyle = FKButtonLoadingPresentation
  typealias ReplacedContentLoadingOptions = FKButtonLoadingReplacementOptions
  typealias SoundFeedback = FKButtonSoundFeedbackConfiguration
  typealias GlobalStyle = FKButtonGlobalStyle
}
