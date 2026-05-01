import UIKit

/// Backdrop host view used by presentation container controllers.
final class FKPresentationBackdropView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = true
    backgroundColor = .clear
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Applies style for supported backdrop appearances.
  func configure(with style: FKBackdropStyle) {
    switch style {
    case .none:
      backgroundColor = .clear
      alpha = 1
    case let .dim(color, alpha):
      backgroundColor = color
      self.alpha = alpha
    }
  }
}
