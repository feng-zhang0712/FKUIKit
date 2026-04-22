import ObjectiveC
import UIKit

@MainActor
private enum FKExpandableTextViewAssociation {
  static var controller: UInt8 = 0
}

/// Convenience APIs that attach `FKExpandableText` behavior to `UITextView`.
///
/// These helpers keep adoption non-invasive by attaching a controller through associated objects
/// rather than requiring subclassing or wrapper views.
@MainActor
public extension UITextView {
  /// Lazily created controller attached to this text view.
  ///
  /// Access this property when you need direct control over rendering, configuration changes, or
  /// custom link handling after initial setup.
  var fk_expandableTextController: FKExpandableTextTextViewController {
    if let controller = objc_getAssociatedObject(self, &FKExpandableTextViewAssociation.controller) as? FKExpandableTextTextViewController {
      return controller
    }
    let controller = FKExpandableTextTextViewController(textView: self)
    objc_setAssociatedObject(self, &FKExpandableTextViewAssociation.controller, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return controller
  }

  /// Applies expandable behavior to this text view.
  ///
  /// - Parameters:
  ///   - text: Rich text content.
  ///   - configuration: Optional configuration.
  ///   - onStateChanged: State callback.
  ///   - onLinkTapped: Link callback.
  ///
  /// The text view keeps its normal link interaction model while expand and collapse behavior is
  /// layered on top through an internal delegate bridge.
  func fk_setExpandableText(
    _ text: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    let controller = fk_expandableTextController
    if let configuration {
      controller.setConfiguration(configuration)
    }
    controller.onStateChanged = onStateChanged
    controller.onLinkTapped = onLinkTapped
    controller.setText(text)
  }

  /// Convenience API for plain string content.
  ///
  /// - Parameters:
  ///   - text: Plain text content.
  ///   - attributes: Optional text attributes.
  ///   - configuration: Optional configuration.
  ///   - onStateChanged: State callback.
  ///   - onLinkTapped: Link callback.
  ///
  /// Use this overload for plain strings when rich text assembly is unnecessary.
  func fk_setExpandableText(
    _ text: String,
    attributes: [NSAttributedString.Key: Any]? = nil,
    configuration: FKExpandableTextConfiguration? = nil,
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    let attributed = NSAttributedString(string: text, attributes: attributes)
    fk_setExpandableText(
      attributed,
      configuration: configuration,
      onStateChanged: onStateChanged,
      onLinkTapped: onLinkTapped
    )
  }
}
