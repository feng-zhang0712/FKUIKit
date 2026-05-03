import UIKit

@MainActor
final class FKTabBarIndicatorView: UIView {
  /// Active indicator style.
  ///
  /// `FKTabBar` updates this whenever appearance changes. This view intentionally does not
  /// try to interpret selection state; it only renders the given style and moves as requested.
  var style: FKTabBarIndicatorStyle = .none {
    didSet { applyStyle() }
  }
  /// Fallback tint used by styles that do not provide their own fill colors.
  ///
  /// For `.line` / `.backgroundHighlight` / `.pill` styles, the configuration's `fill` has priority.
  var color: UIColor = .label {
    didSet { applyStyle() }
  }
  /// Optional custom view factory for `.custom(id:)` styles.
  ///
  /// - Important: The returned view should be lightweight and reusable. The tab bar may call
  ///   this multiple times when styles change, and the view will be hosted and resized to `bounds`.
  var customViewProvider: ((_ id: String) -> UIView?)?
  /// Optional custom renderer for `.custom(id:)` styles.
  ///
  /// This hook is invoked from `layoutSubviews` to allow frame-dependent rendering. Keep it fast;
  /// expensive drawing here can degrade scroll/drag performance.
  var customRenderer: ((_ id: String, _ containerBounds: CGRect, _ container: UIView) -> Void)?

  private let fillView = UIView()
  private let gradientLayer = CAGradientLayer()
  private var hostedCustomView: UIView?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    addSubview(fillView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    fillView.frame = bounds
    gradientLayer.frame = fillView.bounds
    hostedCustomView?.frame = bounds
    switch style {
    case .line(let config):
      fillView.layer.cornerRadius = config.cornerRadius
    case .pill(let config):
      fillView.layer.cornerRadius = max(config.cornerRadius, bounds.height * 0.5)
    case .backgroundHighlight(let config), .gradientHighlight(let config):
      // Treat `cornerRadius` as an upper bound so callers can get capsule semantics by providing
      // a sufficiently large value, while still allowing smaller fixed rounded-rect shapes.
      fillView.layer.cornerRadius = min(config.cornerRadius, bounds.height * 0.5)
    case .custom(let id):
      // Custom indicators can draw relative to current bounds, so we trigger host rendering here.
      customRenderer?(id, bounds, self)
    case .none:
      fillView.layer.cornerRadius = 0
    }

    // Gradient fill is rendered by a sublayer. UIKit cornerRadius does not automatically clip
    // sublayers, so we mirror the radius onto the gradient layer and clip it there.
    // This preserves `fillView` shadows (configured for background indicators) because we do not
    // enable `fillView.layer.masksToBounds`.
    gradientLayer.cornerRadius = fillView.layer.cornerRadius
    gradientLayer.masksToBounds = fillView.layer.cornerRadius > 0
  }

  func move(to frame: CGRect, animation: FKTabBarIndicatorAnimation, animated: Bool) {
    let reduceMotion = UIAccessibility.isReduceMotionEnabled
    guard animated, !reduceMotion else {
      self.frame = frame
      return
    }

    switch animation {
    case .none:
      self.frame = frame
    case .linear(let duration):
      UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut]) {
        self.frame = frame
      }
    case .spring(let duration, let damping, let velocity):
      UIView.animate(
        withDuration: duration,
        delay: 0,
        usingSpringWithDamping: damping,
        initialSpringVelocity: velocity,
        options: [.beginFromCurrentState, .allowUserInteraction]
      ) {
        self.frame = frame
      }
    }
  }

  private func applyStyle() {
    // Reset everything to a known baseline before applying a new style. This avoids visual
    // artifacts caused by layer reuse (e.g. leftover borders/shadows/gradient layers).
    hostedCustomView?.removeFromSuperview()
    hostedCustomView = nil
    gradientLayer.removeFromSuperlayer()
    fillView.layer.borderWidth = 0
    fillView.layer.borderColor = UIColor.clear.cgColor
    fillView.layer.shadowOpacity = 0
    fillView.layer.shadowRadius = 0
    fillView.layer.shadowOffset = .zero
    fillView.layer.shadowColor = UIColor.clear.cgColor

    func applyFill(_ fill: FKTabBarIndicatorFillStyle, fallback: UIColor) {
      switch fill {
      case .solid(let color):
        fillView.backgroundColor = color
      case .gradient(let colors, let startPoint, let endPoint):
        fillView.backgroundColor = .clear
        gradientLayer.colors = (colors.isEmpty ? [fallback, fallback] : colors).map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        fillView.layer.insertSublayer(gradientLayer, at: 0)
      }
    }

    switch style {
    case .none:
      isHidden = true
      fillView.backgroundColor = .clear
    case .line(let config):
      isHidden = false
      applyFill(config.fill, fallback: color)
    case .backgroundHighlight(let config), .gradientHighlight(let config), .pill(let config):
      isHidden = false
      applyFill(config.fill, fallback: color)
      fillView.layer.borderWidth = config.borderWidth
      fillView.layer.borderColor = config.borderColor.cgColor
      fillView.layer.shadowColor = config.shadowColor.cgColor
      fillView.layer.shadowOpacity = config.shadowOpacity
      fillView.layer.shadowRadius = config.shadowRadius
      fillView.layer.shadowOffset = config.shadowOffset
    case .custom(let id):
      isHidden = false
      fillView.backgroundColor = .clear
      if let custom = customViewProvider?(id) {
        custom.frame = bounds
        custom.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(custom)
        hostedCustomView = custom
      }
    }
  }
}

