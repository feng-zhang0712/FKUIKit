import ObjectiveC
import UIKit

@MainActor
private enum FKExpandableTextLabelAssociation {
  static var controller: UInt8 = 0
}

public extension UILabel {
  /// Lazily created controller; retained via associated object.
  var fk_expandableText: FKExpandableTextLabelController {
    if let controller = objc_getAssociatedObject(self, &FKExpandableTextLabelAssociation.controller) as? FKExpandableTextLabelController {
      return controller
    }
    let controller = FKExpandableTextLabelController(label: self)
    objc_setAssociatedObject(self, &FKExpandableTextLabelAssociation.controller, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return controller
  }

  /// Binds expandable behavior using the full attributed string as the logical source.
  func fk_setExpandableText(
    _ text: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil
  ) {
    let controller = fk_expandableText
    if let configuration {
      controller.setConfiguration(configuration)
    }
    controller.onExpansionChange = onExpansionChange
    controller.setText(text)
  }

  /// Plain-string overload; attributes apply to the entire string.
  func fk_setExpandableText(
    _ text: String,
    attributes: [NSAttributedString.Key: Any]? = nil,
    configuration: FKExpandableTextConfiguration? = nil,
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil
  ) {
    let attributed = NSAttributedString(string: text, attributes: attributes)
    fk_setExpandableText(attributed, configuration: configuration, onExpansionChange: onExpansionChange)
  }
}
