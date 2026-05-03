import UIKit

/// Namespace, shared defaults, and attachment APIs for expandable attributed text.
///
/// Use ``attach(to:attributedText:configuration:onExpansionChange:)`` to bind behavior without
/// subclassing. Defaults follow ``defaultConfiguration``, mirroring ``FKBadge`` and ``FKDivider``.
@MainActor
public enum FKExpandableText {
  /// Baseline style when a call site omits `configuration`. Assign at launch for app-wide styling.
  public static var defaultConfiguration = FKExpandableTextConfiguration()

  /// Attaches expandable behavior to a label and returns the controller that owns it.
  ///
  /// - Parameters:
  ///   - label: Host label; the library sets `numberOfLines = 0` and enables interaction.
  ///   - attributedText: Full source string; truncation is applied only for display.
  ///   - configuration: Per-instance style and rules; defaults to ``defaultConfiguration``.
  ///   - onExpansionChange: Invoked after each collapsed ↔ expanded transition completes rendering.
  @discardableResult
  public static func attach(
    to label: UILabel,
    attributedText: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil
  ) -> FKExpandableTextLabelController {
    let resolved = configuration ?? defaultConfiguration
    let controller = label.fk_expandableText
    controller.setConfiguration(resolved)
    controller.onExpansionChange = onExpansionChange
    controller.setText(attributedText)
    return controller
  }

  /// Attaches expandable behavior to a non-scrolling text view and returns its controller.
  ///
  /// The host view is configured for read-only, non-scrolling rich text. External links keep
  /// normal `UITextView` behavior; expand/collapse uses an internal delegate bridge.
  ///
  /// - Parameters:
  ///   - textView: Host text view.
  ///   - attributedText: Full source string.
  ///   - configuration: Per-instance style and rules; defaults to ``defaultConfiguration``.
  ///   - onExpansionChange: Invoked after expansion state changes.
  @discardableResult
  public static func attach(
    to textView: UITextView,
    attributedText: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil
  ) -> FKExpandableTextLinkedTextViewController {
    let resolved = configuration ?? defaultConfiguration
    let controller = textView.fk_expandableText
    controller.setConfiguration(resolved)
    controller.onExpansionChange = onExpansionChange
    controller.setText(attributedText)
    return controller
  }
}
