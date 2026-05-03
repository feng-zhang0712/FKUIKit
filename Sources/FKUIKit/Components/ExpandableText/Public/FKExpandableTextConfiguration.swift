import UIKit

/// Rules and styling for expandable text on `UILabel` or `UITextView`.
///
/// The same value type is used by UIKit attachments and ``FKExpandableTextView``. Defaults match
/// common “read more” patterns; override per screen or set ``FKExpandableText/defaultConfiguration``.
public struct FKExpandableTextConfiguration {
  /// Where the expand / collapse affordance is laid out relative to the body.
  public enum ButtonPlacement {
    /// Inline at the tail of the last visible line (with truncation token when needed).
    case inlineTail
    /// Body is limited to the configured line count; the truncation token ends the clipped body, then the action is on the following line.
    case trailingBottom
  }

  /// Which regions toggle expansion when tapped.
  public enum InteractionMode {
    /// Only the action substring toggles.
    case buttonOnly
    /// Any tap in the label or text view toggles (links on `UITextView` still behave normally).
    case fullTextArea
  }

  /// How the body is clipped while collapsed.
  public enum CollapseRule {
    /// Show at most this many lines; overflow becomes truncation + action.
    case lines(Int)
    /// Do not clip the body; still appends expand / collapse actions when configured.
    case noBodyTruncation
  }

  /// VoiceOver labels for the interactive region.
  public struct Accessibility {
    public var expandLabel: String
    public var collapseLabel: String
    public var hint: String

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

  /// Inserted immediately before the expand action in collapsed `inlineTail` layouts.
  public var truncationToken: NSAttributedString
  /// Shown while collapsed when truncation applies (or under `noBodyTruncation`).
  public var expandActionText: NSAttributedString
  /// Shown while expanded unless `oneWayExpand` removes the affordance.
  public var collapseActionText: NSAttributedString
  public var collapseRule: CollapseRule
  public var buttonPlacement: ButtonPlacement
  public var interactionMode: InteractionMode
  /// After first expansion, the UI stays expanded and ignores collapse.
  public var oneWayExpand: Bool
  public var accessibility: Accessibility

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
    accessibility: Accessibility = .init()
  ) {
    self.truncationToken = truncationToken
    self.expandActionText = expandActionText
    self.collapseActionText = collapseActionText
    self.collapseRule = collapseRule
    self.buttonPlacement = buttonPlacement
    self.interactionMode = interactionMode
    self.oneWayExpand = oneWayExpand
    self.accessibility = accessibility
  }
}
