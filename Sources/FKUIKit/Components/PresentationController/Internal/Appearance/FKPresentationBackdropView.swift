import UIKit

/// Backdrop host view used by presentation container controllers.
final class FKPresentationBackdropView: UIView {
  private var dimColor: UIColor = .black
  private var isDimStyle: Bool = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = true
    backgroundColor = .clear
    alpha = 1
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Applies style for supported backdrop appearances.
  func configure(with style: FKBackdropStyle) {
    switch style {
    case .none:
      isDimStyle = false
      backgroundColor = .clear
      alpha = 1
    case let .dim(color, alpha):
      isDimStyle = true
      dimColor = color
      setDimAlpha(alpha)
    }
  }

  /// Updates dim intensity without disabling hit-testing.
  ///
  /// - Important: Do not drive dim intensity using `view.alpha` because `alpha == 0`
  ///   makes the view fail hit-testing, which breaks tap-to-dismiss.
  func setDimAlpha(_ alpha: CGFloat) {
    guard isDimStyle else { return }
    let a = min(max(alpha, 0), 1)
    backgroundColor = dimColor.withAlphaComponent(a)
    self.alpha = 1
  }
}
