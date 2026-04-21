//
// FKEmptyStateModel.swift
//
// Integration notes (recommended):
// - Attach overlays to `UIViewController.view` (`UIView.fk_applyEmptyState`) or `UIScrollView` — avoid `UITableView.backgroundView` so refresh controls stay on top.
// - Use `FKEmptyStatePhase`: `.content` hides the overlay; `.loading` + `skipsLoadingWhileRefreshing` skips the placeholder while `UIRefreshControl.isRefreshing`.
// - Error UI always shows a retry control when `phase == .error` (default title from `defaultRetryButtonTitle`).
// - Global fonts/colors: copy `FKEmptyStateGlobalDefaults.template` in AppDelegate and mutate, or build models from scratch.
// - Lottie: assign `customAccessoryView` + `customAccessoryPlacement` (host `AnimationView` yourself; no Lottie dependency in FKUIKit).
// - Default `backgroundColor` is `systemBackground` so overlays hide underlying lists in landscape; use `.clear` only for intentional transparency.
//

import UIKit

// MARK: - Custom accessory placement

/// Positions `customAccessoryView` (e.g. Lottie) relative to the image slot and text stack.
public enum FKEmptyStateCustomPlacement: Equatable, Sendable {
  /// Shows only the custom view in the illustration row (built-in image hidden).
  case replaceImage
  /// Custom view above `UIImageView`.
  case aboveImage
  /// Custom view between image and title.
  case belowImage
  /// Custom view after description, before spinner/button slot (spinner only in loading phase).
  case belowDescription
}

// MARK: - Content alignment

/// Vertical placement strategy for the placeholder content inside the host view.
public enum FKEmptyStateContentAlignment: Equatable, Sendable {
  /// Centers content vertically in the safe area.
  case center
  /// Pins content to the top safe area with a configurable offset.
  case top
}

// MARK: - Preset scenarios

/// High-level product scenarios used by `FKEmptyStateModel.scenario(_:)` to pre-fill copy and `FKEmptyStatePhase`.
///
/// Localize strings in your app before shipping.
public enum FKEmptyStateScenario: CaseIterable, Sendable {
  /// Offline or transport failure messaging; primary action reloads.
  case noNetwork
  /// Search returned nothing.
  case noSearchResult
  /// Favorites / wishlist empty.
  case noFavorites
  /// Order history empty.
  case noOrders
  /// Inbox / notifications empty.
  case noMessages
  /// Request failed; uses `phase == .error` and mandatory retry styling.
  case loadFailed
  /// Authorization / feature gate.
  case noPermission
  /// Account required.
  case notLoggedIn
}

// MARK: - Button style

/// Visual style for the primary action button (filled configuration on iOS 15+).
public struct FKEmptyStateButtonStyle {
  /// Button title; `nil` hides the button unless `phase == .error` (retry is forced).
  public var title: String?
  /// Foreground (text) color.
  public var titleColor: UIColor
  /// Title font (also applied where configuration supports it).
  public var font: UIFont
  /// Fill color for filled button style.
  public var backgroundColor: UIColor
  /// Corner radius applied to the button layer.
  public var cornerRadius: CGFloat
  /// Padding inside the button around the title.
  public var contentInsets: UIEdgeInsets
  /// Optional stroke; `nil` means no border.
  public var borderColor: UIColor?
  /// Hairline width when `borderColor` is set.
  public var borderWidth: CGFloat

  public init(
    title: String? = nil,
    titleColor: UIColor = .white,
    font: UIFont = .systemFont(ofSize: 15, weight: .semibold),
    backgroundColor: UIColor = .systemBlue,
    cornerRadius: CGFloat = 10,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16),
    borderColor: UIColor? = nil,
    borderWidth: CGFloat = 0
  ) {
    self.title = title
    self.titleColor = titleColor
    self.font = font
    self.backgroundColor = backgroundColor
    self.cornerRadius = cornerRadius
    self.contentInsets = contentInsets
    self.borderColor = borderColor
    self.borderWidth = borderWidth
  }
}

// MARK: - Model

/// Immutable-friendly configuration struct for `FKEmptyStateView`; use fluent helpers (`withTitle`, etc.) to derive copies.
public struct FKEmptyStateModel {
  /// Controls which layout branch runs inside `FKEmptyStateView` (loading vs empty/error vs hidden).
  public var phase: FKEmptyStatePhase

  /// Main illustration; hidden when `isImageHidden` or `nil` (unless `customAccessoryView` replaces it).
  public var image: UIImage?
  /// Primary headline for empty/error; also fallback text for loading if `loadingMessage` is `nil`.
  public var title: String?
  /// Secondary body copy (empty/error; optional during loading via `hidesDescriptionForLoadingPhase`).
  public var description: String?
  /// Preferred loading subtitle; when `nil` and `phase == .loading`, `title` is shown under the spinner.
  public var loadingMessage: String?
  /// Primary button look-and-feel.
  public var buttonStyle: FKEmptyStateButtonStyle

  /// Hides the image view even when `image` is non-nil.
  public var isImageHidden: Bool
  /// Hides the title label.
  public var isTitleHidden: Bool
  /// Hides the description label.
  public var isDescriptionHidden: Bool
  /// Hides the action button (ignored for `phase == .error`, which always shows retry).
  public var isButtonHidden: Bool

  public var titleColor: UIColor
  public var descriptionColor: UIColor
  public var titleFont: UIFont
  public var descriptionFont: UIFont
  /// Fixed image dimensions when set; intrinsic sizing otherwise.
  public var imageSize: CGSize?

  /// Vertical spacing between stack subviews.
  public var verticalSpacing: CGFloat
  /// Applied via `directionalLayoutMargins` on the overlay root.
  public var contentInsets: UIEdgeInsets
  /// Max width of the centered content column.
  public var maxContentWidth: CGFloat
  /// Vertical content alignment in the host view.
  public var contentAlignment: FKEmptyStateContentAlignment
  /// Additional Y offset for the content container (positive = lower, negative = higher).
  public var verticalOffset: CGFloat
  /// Root view background behind gradient/dimming (defaults to opaque system color).
  public var backgroundColor: UIColor
  /// When non-empty, draws a `CAGradientLayer` under subviews.
  public var gradientColors: [UIColor]
  /// Unit gradient start (0…1).
  public var gradientStartPoint: CGPoint
  /// Unit gradient end (0…1).
  public var gradientEndPoint: CGPoint

  /// Extra black dimming alpha on `blockingDimmingView` (0 = invisible dimmer).
  public var blockingOverlayAlpha: CGFloat

  /// When `true`, background taps trigger `endEditing(true)` (search fields, etc.).
  public var supportsTapToDismissKeyboard: Bool
  /// Fade duration for `UIView` transitions and extension-driven show/hide animations.
  public var fadeDuration: TimeInterval
  /// When `false`, `UIScrollView` scrolling is disabled while the overlay is visible.
  public var keepScrollEnabled: Bool
  /// Enables `fk_refreshEmptyStateAutomatically` behavior on `UIScrollView`.
  public var automaticallyShowsWhenContentFits: Bool

  /// Tint for `UIActivityIndicatorView` in loading phase.
  public var loadingTintColor: UIColor
  /// Spinner size (`.medium` / `.large`, etc.).
  public var activityIndicatorStyle: UIActivityIndicatorView.Style

  /// Hides the image slot entirely during loading.
  public var hidesImageForLoadingPhase: Bool
  /// Suppresses description text during loading when you want spinner + title only.
  public var hidesDescriptionForLoadingPhase: Bool

  /// Skips loading overlay while `UIRefreshControl.isRefreshing` (avoid duplicate spinners).
  public var skipsLoadingWhileRefreshing: Bool

  /// Pins content above the keyboard using `keyboardLayoutGuide` when `true`.
  public var adjustsPositionForKeyboard: Bool

  /// Optional custom view (e.g. Lottie); placement follows `customAccessoryPlacement`.
  public var customAccessoryView: UIView?
  public var customAccessoryPlacement: FKEmptyStateCustomPlacement

  public init(
    phase: FKEmptyStatePhase = .empty,
    image: UIImage? = nil,
    title: String? = nil,
    description: String? = nil,
    loadingMessage: String? = nil,
    buttonStyle: FKEmptyStateButtonStyle = FKEmptyStateButtonStyle(),
    isImageHidden: Bool = false,
    isTitleHidden: Bool = false,
    isDescriptionHidden: Bool = false,
    isButtonHidden: Bool = true,
    titleColor: UIColor = .label,
    descriptionColor: UIColor = .secondaryLabel,
    titleFont: UIFont = .systemFont(ofSize: 18, weight: .semibold),
    descriptionFont: UIFont = .systemFont(ofSize: 14, weight: .regular),
    imageSize: CGSize? = nil,
    verticalSpacing: CGFloat = 10,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20),
    maxContentWidth: CGFloat = 320,
    contentAlignment: FKEmptyStateContentAlignment = .center,
    verticalOffset: CGFloat = 0,
    /// Opaque by default so the overlay hides underlying scroll content in any orientation (set `.clear` only if you intentionally need a see-through layer).
    backgroundColor: UIColor = .systemBackground,
    gradientColors: [UIColor] = [],
    gradientStartPoint: CGPoint = CGPoint(x: 0.5, y: 0),
    gradientEndPoint: CGPoint = CGPoint(x: 0.5, y: 1),
    blockingOverlayAlpha: CGFloat = 0,
    supportsTapToDismissKeyboard: Bool = true,
    fadeDuration: TimeInterval = 0.25,
    keepScrollEnabled: Bool = true,
    automaticallyShowsWhenContentFits: Bool = false,
    loadingTintColor: UIColor = .secondaryLabel,
    activityIndicatorStyle: UIActivityIndicatorView.Style = .large,
    hidesImageForLoadingPhase: Bool = true,
    hidesDescriptionForLoadingPhase: Bool = false,
    skipsLoadingWhileRefreshing: Bool = true,
    adjustsPositionForKeyboard: Bool = true,
    customAccessoryView: UIView? = nil,
    customAccessoryPlacement: FKEmptyStateCustomPlacement = .belowImage
  ) {
    self.phase = phase
    self.image = image
    self.title = title
    self.description = description
    self.loadingMessage = loadingMessage
    self.buttonStyle = buttonStyle
    self.isImageHidden = isImageHidden
    self.isTitleHidden = isTitleHidden
    self.isDescriptionHidden = isDescriptionHidden
    self.isButtonHidden = isButtonHidden
    self.titleColor = titleColor
    self.descriptionColor = descriptionColor
    self.titleFont = titleFont
    self.descriptionFont = descriptionFont
    self.imageSize = imageSize
    self.verticalSpacing = max(0, verticalSpacing)
    self.contentInsets = contentInsets
    self.maxContentWidth = max(180, maxContentWidth)
    self.contentAlignment = contentAlignment
    self.verticalOffset = verticalOffset
    self.backgroundColor = backgroundColor
    self.gradientColors = gradientColors
    self.gradientStartPoint = gradientStartPoint
    self.gradientEndPoint = gradientEndPoint
    self.blockingOverlayAlpha = min(1, max(0, blockingOverlayAlpha))
    self.supportsTapToDismissKeyboard = supportsTapToDismissKeyboard
    self.fadeDuration = max(0, fadeDuration)
    self.keepScrollEnabled = keepScrollEnabled
    self.automaticallyShowsWhenContentFits = automaticallyShowsWhenContentFits
    self.loadingTintColor = loadingTintColor
    self.activityIndicatorStyle = activityIndicatorStyle
    self.hidesImageForLoadingPhase = hidesImageForLoadingPhase
    self.hidesDescriptionForLoadingPhase = hidesDescriptionForLoadingPhase
    self.skipsLoadingWhileRefreshing = skipsLoadingWhileRefreshing
    self.adjustsPositionForKeyboard = adjustsPositionForKeyboard
    self.customAccessoryView = customAccessoryView
    self.customAccessoryPlacement = customAccessoryPlacement
  }
}

// MARK: - Factory & fluent helpers

public extension FKEmptyStateModel {
  /// Default retry title when `phase == .error` and `buttonStyle.title` is empty.
  static let defaultRetryButtonTitle: String = "Retry"

  /// Returns a model pre-filled for `scenario` (English copy in the library; replace in app).
  static func scenario(_ scenario: FKEmptyStateScenario) -> FKEmptyStateModel {
    switch scenario {
    case .noNetwork:
      return FKEmptyStateModel(
        phase: .empty,
        title: "No network",
        description: "Check your connection and try again.",
        buttonStyle: FKEmptyStateButtonStyle(title: "Reload"),
        isButtonHidden: false
      )
    case .noSearchResult:
      return FKEmptyStateModel(
        phase: .empty,
        title: "No results",
        description: "Try different keywords.",
        isButtonHidden: true
      )
    case .noFavorites:
      return FKEmptyStateModel(
        phase: .empty,
        title: "No favorites yet",
        description: "Save items you like to see them here.",
        buttonStyle: FKEmptyStateButtonStyle(title: "Go home"),
        isButtonHidden: false
      )
    case .noOrders:
      return FKEmptyStateModel(
        phase: .empty,
        title: "No orders",
        description: "Place an order to track it here.",
        buttonStyle: FKEmptyStateButtonStyle(title: "Shop now"),
        isButtonHidden: false
      )
    case .noMessages:
      return FKEmptyStateModel(
        phase: .empty,
        title: "No messages",
        description: "New notifications will appear here.",
        isButtonHidden: true
      )
    case .loadFailed:
      return FKEmptyStateModel(
        phase: .error,
        title: "Couldn’t load",
        description: "The request timed out or the server returned an error. Try again.",
        buttonStyle: FKEmptyStateButtonStyle(title: defaultRetryButtonTitle),
        isButtonHidden: false
      )
    case .noPermission:
      return FKEmptyStateModel(
        phase: .empty,
        title: "No access",
        description: "You don’t have permission to view this content.",
        buttonStyle: FKEmptyStateButtonStyle(title: "OK"),
        isButtonHidden: false
      )
    case .notLoggedIn:
      return FKEmptyStateModel(
        phase: .empty,
        title: "Sign in required",
        description: "Log in to see your data here.",
        buttonStyle: FKEmptyStateButtonStyle(title: "Sign in"),
        isButtonHidden: false
      )
    }
  }

  /// Returns a model for a custom business state identifier.
  ///
  /// - Parameters:
  ///   - identifier: Domain-specific key, such as `"maintenance"` or `"geo_restricted"`.
  ///   - title: Primary title.
  ///   - description: Secondary message.
  ///   - buttonTitle: Optional action title.
  static func customState(
    identifier: String,
    title: String?,
    description: String? = nil,
    buttonTitle: String? = nil
  ) -> FKEmptyStateModel {
    FKEmptyStateModel(
      phase: .custom(identifier),
      title: title,
      description: description,
      buttonStyle: FKEmptyStateButtonStyle(title: buttonTitle),
      isButtonHidden: buttonTitle == nil
    )
  }

  /// Returns a copy with `title` replaced.
  func withTitle(_ text: String?) -> Self {
    var copy = self
    copy.title = text
    return copy
  }

  /// Returns a copy with `description` replaced.
  func withDescription(_ text: String?) -> Self {
    var copy = self
    copy.description = text
    return copy
  }

  /// Returns a copy with `image` replaced.
  func withImage(_ image: UIImage?) -> Self {
    var copy = self
    copy.image = image
    return copy
  }

  /// Returns a copy with `buttonStyle.title` set; hides the button when `text == nil` (except error phase enforcement in the view).
  func withButtonTitle(_ text: String?) -> Self {
    var copy = self
    copy.buttonStyle.title = text
    copy.isButtonHidden = (text == nil)
    return copy
  }

  /// Returns a copy with `phase` replaced.
  func withPhase(_ phase: FKEmptyStatePhase) -> Self {
    var copy = self
    copy.phase = phase
    return copy
  }

  /// Returns a copy with top/center alignment and vertical offset.
  func withLayout(alignment: FKEmptyStateContentAlignment, verticalOffset: CGFloat = 0) -> Self {
    var copy = self
    copy.contentAlignment = alignment
    copy.verticalOffset = verticalOffset
    return copy
  }
}
