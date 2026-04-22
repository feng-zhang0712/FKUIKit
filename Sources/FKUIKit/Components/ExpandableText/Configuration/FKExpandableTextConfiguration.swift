import UIKit

/// Defines how `FKExpandableText` renders, truncates, animates, and reacts to user interaction.
///
/// Use this type to customize per-instance behavior while keeping integration non-invasive.
/// The same configuration can be applied to both `UILabel` and `UITextView` entry points, and it
/// also powers the SwiftUI bridge. The component implementation is compatible with iOS 13.0+,
/// while package-level platform requirements still follow the repository configuration.
public struct FKExpandableTextConfiguration {
  /// Defines where the expand or collapse action is rendered.
  public enum ButtonPlacement {
    /// The button is appended to the end of the last visible line.
    case inlineTail
    /// The button is rendered as a separate right-aligned line.
    case trailingBottom
  }

  /// Defines how the component responds to user taps.
  public enum InteractionMode {
    /// Only taps on the expand/collapse action are handled.
    case buttonOnly
    /// Tapping anywhere in the text area toggles the state.
    case fullTextArea
  }

  /// Defines the animation style used when the rendered state changes.
  public enum Animation {
    /// No animation.
    case none
    /// UIKit curve-based animation.
    case curve(duration: TimeInterval, options: UIView.AnimationOptions)
    /// UIKit spring animation.
    case spring(
      duration: TimeInterval,
      dampingRatio: CGFloat,
      velocity: CGFloat,
      options: UIView.AnimationOptions
    )
  }

  /// Defines the rule used when rendering collapsed content.
  public enum CollapseRule {
    /// Truncate to a specific line count.
    case lines(Int)
    /// Do not truncate text body; this is useful if only a toggle button is desired.
    case noBodyTruncation
  }

  /// Accessibility strings used for VoiceOver and other assistive technologies.
  public struct Accessibility {
    /// Label for the expand action.
    public var expandLabel: String
    /// Label for the collapse action.
    public var collapseLabel: String
    /// Hint for screen readers.
    public var hint: String

    /// Creates accessibility metadata for the expandable content.
    ///
    /// - Parameters:
    ///   - expandLabel: Spoken label used while the content is collapsed.
    ///   - collapseLabel: Spoken label used while the content is expanded.
    ///   - hint: Additional hint describing the available interaction.
    public init(
      expandLabel: String = "Expand text",
      collapseLabel: String = "Collapse text",
      hint: String = "Double-tap to toggle text expansion."
    ) {
      self.expandLabel = expandLabel
      self.collapseLabel = collapseLabel
      self.hint = hint
    }
  }

  /// Text inserted before the action in collapsed mode.
  ///
  /// This is typically an ellipsis-like suffix such as `"… "` or `"..."`.
  public var truncationToken: NSAttributedString
  /// Rich text used as the expand action while content is collapsed.
  public var expandActionText: NSAttributedString
  /// Rich text used as the collapse action while content is expanded.
  public var collapseActionText: NSAttributedString
  /// Rule that determines how collapsed content is generated.
  public var collapseRule: CollapseRule
  /// Placement of the expand or collapse action.
  public var buttonPlacement: ButtonPlacement
  /// Tap interaction mode used by the rendered view.
  public var interactionMode: InteractionMode
  /// Indicates whether collapsing is disabled after the first successful expansion.
  public var oneWayExpand: Bool
  /// Animation applied when switching between collapsed and expanded states.
  public var animation: Animation
  /// Accessibility metadata used to describe the control to assistive technologies.
  public var accessibility: Accessibility

  /// Creates a configuration for expandable text rendering.
  ///
  /// - Parameters:
  ///   - truncationToken: Text inserted before the expand action when the content is collapsed.
  ///   - expandActionText: Attributed action displayed while the content is collapsed.
  ///   - collapseActionText: Attributed action displayed while the content is expanded.
  ///   - collapseRule: Rule that determines whether and how the body text is truncated.
  ///   - buttonPlacement: Placement for the action text within the rendered output.
  ///   - interactionMode: Tap behavior for the host view.
  ///   - oneWayExpand: A Boolean value that disables collapsing after the first expansion.
  ///   - animation: Animation used when state changes are rendered.
  ///   - accessibility: Accessibility metadata used by assistive technologies.
  ///
  /// Use this initializer when screen-specific customization is needed. For app-wide defaults,
  /// prefer assigning a shared value to `FKExpandableTextGlobalConfiguration.shared`.
  public init(
    truncationToken: NSAttributedString = NSAttributedString(string: "... "),
    expandActionText: NSAttributedString = NSAttributedString(
      string: "Read more",
      attributes: [
        .foregroundColor: UIColor.systemBlue,
        .font: UIFont.preferredFont(forTextStyle: .body),
      ]
    ),
    collapseActionText: NSAttributedString = NSAttributedString(
      string: "Collapse",
      attributes: [
        .foregroundColor: UIColor.systemBlue,
        .font: UIFont.preferredFont(forTextStyle: .body),
      ]
    ),
    collapseRule: CollapseRule = .lines(3),
    buttonPlacement: ButtonPlacement = .inlineTail,
    interactionMode: InteractionMode = .buttonOnly,
    oneWayExpand: Bool = false,
    animation: Animation = .curve(duration: 0.25, options: [.curveEaseInOut]),
    accessibility: Accessibility = .init()
  ) {
    self.truncationToken = truncationToken
    self.expandActionText = expandActionText
    self.collapseActionText = collapseActionText
    self.collapseRule = collapseRule
    self.buttonPlacement = buttonPlacement
    self.interactionMode = interactionMode
    self.oneWayExpand = oneWayExpand
    self.animation = animation
    self.accessibility = accessibility
  }
}

/// Stores the global default configuration shared by `FKExpandableText` entry points.
///
/// Assigning `shared` lets you centralize product-wide styling without changing each integration
/// site. Public UI APIs remain main-actor isolated, which keeps usage aligned with UIKit and
/// SwiftUI threading expectations.
@MainActor
public enum FKExpandableTextGlobalConfiguration {
  // Protects the shared configuration value during read and write access.
  private static let lock = NSLock()
  private static var _shared = FKExpandableTextConfiguration()

  /// Shared default configuration used when no per-instance override is provided.
  ///
  /// Read this value to inspect current defaults, or assign a new configuration to update the
  /// baseline styling and interaction behavior for subsequent integrations.
  public static var shared: FKExpandableTextConfiguration {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _shared
    }
    set {
      lock.lock()
      _shared = newValue
      lock.unlock()
    }
  }
}
