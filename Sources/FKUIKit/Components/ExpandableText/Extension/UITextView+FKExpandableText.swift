import ObjectiveC
import UIKit

@MainActor
private enum FKExpandableTextViewAssociation {
  static var controller: UInt8 = 0
}

public extension UITextView {
  /// Lazily created controller; retained via associated object.
  var fk_expandableText: FKExpandableTextLinkedTextViewController {
    if let controller = objc_getAssociatedObject(self, &FKExpandableTextViewAssociation.controller) as? FKExpandableTextLinkedTextViewController {
      return controller
    }
    let controller = FKExpandableTextLinkedTextViewController(textView: self)
    objc_setAssociatedObject(self, &FKExpandableTextViewAssociation.controller, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return controller
  }

  func fk_setExpandableText(
    _ text: NSAttributedString,
    configuration: FKExpandableTextConfiguration? = nil,
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    let controller = fk_expandableText
    if let configuration {
      controller.setConfiguration(configuration)
    }
    controller.onExpansionChange = onExpansionChange
    controller.onLinkTapped = onLinkTapped
    controller.setText(text)
  }

  func fk_setExpandableText(
    _ text: String,
    attributes: [NSAttributedString.Key: Any]? = nil,
    configuration: FKExpandableTextConfiguration? = nil,
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    let attributed = NSAttributedString(string: text, attributes: attributes)
    fk_setExpandableText(
      attributed,
      configuration: configuration,
      onExpansionChange: onExpansionChange,
      onLinkTapped: onLinkTapped
    )
  }
}
