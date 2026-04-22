import UIKit

/// Entry point for attaching expandable and collapsible text behavior to UIKit views.
///
/// `FKExpandableText` provides a non-invasive integration surface for both `UILabel` and
/// `UITextView`. It keeps adoption lightweight, works with shared configuration defaults, and is
/// intended for iOS 13.0+ component usage scenarios.
@MainActor
public enum FKExpandableText {
  /// Applies expandable behavior to a label and returns the controller managing that behavior.
  ///
  /// - Parameters:
  ///   - label: Target label.
  ///   - text: Rich text content.
  ///   - configuration: Optional per-instance configuration override.
  ///   - onStateChanged: State callback.
  /// - Returns: A reusable controller instance that can be stored for further manual updates.
  ///
  /// Use this API when you prefer an explicit controller reference instead of the extension-based
  /// convenience methods.
  @discardableResult
  public static func apply(
    to label: UILabel,
    text: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil
  ) -> FKExpandableTextLabelController {
    let controller = FKExpandableTextLabelController(
      label: label,
      configuration: configuration ?? FKExpandableTextGlobalConfiguration.shared
    )
    controller.onStateChanged = onStateChanged
    controller.setText(text)
    return controller
  }

  /// Applies expandable behavior to a text view and returns the controller managing that behavior.
  ///
  /// - Parameters:
  ///   - textView: Target text view.
  ///   - text: Rich text content.
  ///   - configuration: Optional per-instance configuration override.
  ///   - onStateChanged: State callback.
  /// - Returns: A reusable controller instance that can be stored for further manual updates.
  ///
  /// This entry point preserves normal `UITextView` link handling while adding expandable text
  /// behavior through an internal delegate bridge.
  @discardableResult
  public static func apply(
    to textView: UITextView,
    text: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil
  ) -> FKExpandableTextTextViewController {
    let controller = FKExpandableTextTextViewController(
      textView: textView,
      configuration: configuration ?? FKExpandableTextGlobalConfiguration.shared
    )
    controller.onStateChanged = onStateChanged
    controller.setText(text)
    return controller
  }
}
