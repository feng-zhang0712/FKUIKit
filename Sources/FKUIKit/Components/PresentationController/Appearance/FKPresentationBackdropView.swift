import UIKit

/// Backdrop host view used by presentation container controllers.
final class FKPresentationBackdropView: UIView {
  private var visualEffectView: UIVisualEffectView?
  private var vibrancyView: UIVisualEffectView?
  private var highlightLayer: CAGradientLayer?
  private var noiseLayer: CALayer?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = true
    backgroundColor = .clear
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Applies style for dim, blur, or liquid-glass-like backdrop appearances.
  func configure(with style: FKBackdropStyle) {
    visualEffectView?.removeFromSuperview()
    visualEffectView = nil
    vibrancyView?.removeFromSuperview()
    vibrancyView = nil
    highlightLayer?.removeFromSuperlayer()
    highlightLayer = nil
    noiseLayer?.removeFromSuperlayer()
    noiseLayer = nil

    switch style {
    case .none:
      backgroundColor = .clear
      alpha = 1
    case let .dim(color, alpha):
      backgroundColor = color
      self.alpha = alpha
    case let .blur(effect, alpha, vibrancy):
      let effectView = UIVisualEffectView(effect: UIBlurEffect(style: effect))
      effectView.frame = bounds
      effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      effectView.alpha = alpha
      addSubview(effectView)
      visualEffectView = effectView
      backgroundColor = .clear
      if let vibrancy {
        let vibEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: effect), style: vibrancy)
        let vibView = UIVisualEffectView(effect: vibEffect)
        vibView.frame = bounds
        vibView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.contentView.addSubview(vibView)
        vibrancyView = vibView
      }
    case let .liquidGlass(liquidGlassConfiguration):
      let shouldDowngrade = (liquidGlassConfiguration.downgradeWhenReduceTransparencyEnabled && UIAccessibility.isReduceTransparencyEnabled)
        || (liquidGlassConfiguration.simplifyInLowPowerMode && ProcessInfo.processInfo.isLowPowerModeEnabled)
      if shouldDowngrade {
        configure(with: .blur(effect: .systemUltraThinMaterial, alpha: 1, vibrancy: nil))
        return
      }

      let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
      effectView.frame = bounds
      effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      effectView.alpha = liquidGlassConfiguration.intensity
      addSubview(effectView)
      visualEffectView = effectView

      // Best-effort "liquid glass": blur + highlight gradient + subtle noise + adaptive tint.
      let isDark = traitCollection.userInterfaceStyle == .dark
      backgroundColor = (isDark ? UIColor.black : UIColor.white).withAlphaComponent(0.06 * liquidGlassConfiguration.intensity)

      if liquidGlassConfiguration.showsHighlight {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
          (isDark ? UIColor.white.withAlphaComponent(0.10) : UIColor.white.withAlphaComponent(0.20)).cgColor,
          (isDark ? UIColor.white.withAlphaComponent(0.02) : UIColor.white.withAlphaComponent(0.06)).cgColor,
          (isDark ? UIColor.black.withAlphaComponent(0.10) : UIColor.black.withAlphaComponent(0.08)).cgColor,
        ]
        gradient.locations = [0, 0.45, 1]
        gradient.startPoint = CGPoint(x: 0.1, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.9, y: 1.0)
        layer.addSublayer(gradient)
        highlightLayer = gradient
      }

      if liquidGlassConfiguration.showsNoise {
        let noise = CALayer()
        noise.frame = bounds
        noise.contents = Self.noiseImage(scale: UIScreen.main.scale)?.cgImage
        noise.contentsGravity = .resizeAspectFill
        noise.opacity = (isDark ? 0.12 : 0.08) * Float(liquidGlassConfiguration.intensity)
        noise.compositingFilter = "overlayBlendMode"
        layer.addSublayer(noise)
        noiseLayer = noise
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    visualEffectView?.frame = bounds
    vibrancyView?.frame = bounds
    highlightLayer?.frame = bounds
    noiseLayer?.frame = bounds
  }

  private static func noiseImage(scale: CGFloat) -> UIImage? {
    struct Cache { nonisolated(unsafe) static var image: UIImage? }
    if let img = Cache.image { return img }

    let size = CGSize(width: 96, height: 96)
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { ctx in
      let context = ctx.cgContext
      for _ in 0..<700 {
        let x = CGFloat.random(in: 0..<size.width)
        let y = CGFloat.random(in: 0..<size.height)
        let a = CGFloat.random(in: 0.0...0.18)
        context.setFillColor(UIColor.white.withAlphaComponent(a).cgColor)
        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
      }
    }
    Cache.image = image
    return image
  }
}
