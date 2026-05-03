#if canImport(UIKit)
import UIKit

public extension UIButton {
  /// Sets the title for multiple control states in one call. When `states` is empty, updates `.normal`, `.highlighted`, `.selected`, and `.disabled`.
  func fk_setTitle(_ title: String?, for states: UIControl.State...) {
    let targetStates: [UIControl.State] = states.isEmpty
      ? [.normal, .highlighted, .selected, .disabled]
      : states
    for state in targetStates {
      setTitle(title, for: state)
    }
  }

  /// Sets the image for multiple control states in one call. When `states` is empty, updates `.normal`, `.highlighted`, `.selected`, and `.disabled`.
  func fk_setImage(_ image: UIImage?, for states: UIControl.State...) {
    let targetStates: [UIControl.State] = states.isEmpty
      ? [.normal, .highlighted, .selected, .disabled]
      : states
    for state in targetStates {
      setImage(image, for: state)
    }
  }
}

#endif
