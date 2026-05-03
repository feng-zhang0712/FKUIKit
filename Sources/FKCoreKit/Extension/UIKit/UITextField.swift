#if canImport(UIKit)
import UIKit

public extension UITextField {
  /// Clears `text` and optionally emits `.editingChanged`.
  func fk_clearText(notifyEditingChanged: Bool = true) {
    text = ""
    if notifyEditingChanged {
      sendActions(for: .editingChanged)
    }
  }

  /// Selects the entire current textual range, if any.
  func fk_selectAllText() {
    selectedTextRange = textRange(from: beginningOfDocument, to: endOfDocument)
  }
}

#endif
