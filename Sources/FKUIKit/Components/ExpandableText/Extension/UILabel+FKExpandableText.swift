import ObjectiveC
import UIKit

@MainActor
private enum FKExpandableTextLabelAssociation {
  static var controller: UInt8 = 0
}

/// Convenience APIs that attach `FKExpandableText` behavior to `UILabel`.
///
/// These helpers are non-invasive: the label itself remains the host view and no subclassing is
/// required. The behavior is implemented by an associated controller that is created lazily.
@MainActor
public extension UILabel {
  /// Lazily created controller attached to this label.
  ///
  /// Access this property when you need direct control over rendering or state updates after the
  /// initial setup. The controller is retained using Objective-C associated objects.
  var fk_expandableTextController: FKExpandableTextLabelController {
    if let controller = objc_getAssociatedObject(self, &FKExpandableTextLabelAssociation.controller) as? FKExpandableTextLabelController {
      return controller
    }
    let controller = FKExpandableTextLabelController(label: self)
    objc_setAssociatedObject(self, &FKExpandableTextLabelAssociation.controller, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return controller
  }

  /// Applies expandable behavior to this label.
  ///
  /// - Parameters:
  ///   - text: Rich text content.
  ///   - configuration: Optional configuration.
  ///   - onStateChanged: State callback.
  ///
  /// Call this after the label has a meaningful layout width for the most accurate truncation.
  func fk_setExpandableText(
    _ text: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil
  ) {
    let controller = fk_expandableTextController
    if let configuration {
      controller.setConfiguration(configuration)
    }
    controller.onStateChanged = onStateChanged
    controller.setText(text)
  }

  /// Convenience API for plain string content.
  ///
  /// - Parameters:
  ///   - text: Plain text content.
  ///   - attributes: Optional text attributes.
  ///   - configuration: Optional configuration.
  ///   - onStateChanged: State callback.
  ///
  /// This overload is convenient for simple text while still supporting custom styling through
  /// `attributes`.
  func fk_setExpandableText(
    _ text: String,
    attributes: [NSAttributedString.Key: Any]? = nil,
    configuration: FKExpandableTextConfiguration? = nil,
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil
  ) {
    let attributed = NSAttributedString(string: text, attributes: attributes)
    fk_setExpandableText(attributed, configuration: configuration, onStateChanged: onStateChanged)
  }
}
