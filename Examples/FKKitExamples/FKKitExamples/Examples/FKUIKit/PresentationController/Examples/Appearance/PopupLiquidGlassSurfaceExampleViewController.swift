import UIKit
import FKUIKit

/// Demonstrates a liquid-glass-like surface inside the popup panel itself.
final class PopupLiquidGlassSurfaceExampleViewController: FKPresentationExamplePageViewController {
  private var intensity: Float = 1.0
  private var showHighlight: Bool = true
  private var showNoise: Bool = true

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Popup surface liquid glass",
      subtitle: "Use a liquid-glass-like style for the popup surface itself.",
      notes: "This is panel-level rendering and does not rely on backdrop liquid glass."
    )

    addView(
      FKExampleControls.slider(
        title: "Intensity",
        value: intensity,
        range: 0.2...1.0,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] value in
        self?.intensity = value
      }
    )

    addView(
      FKExampleControls.toggle(
        title: "Show highlight layer",
        isOn: showHighlight
      ) { [weak self] isOn in
        self?.showHighlight = isOn
      }
    )

    addView(
      FKExampleControls.toggle(
        title: "Show noise layer",
        isOn: showNoise
      ) { [weak self] isOn in
        self?.showNoise = isOn
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let content = PopupLiquidGlassSurfaceContentViewController(
        intensity: CGFloat(self.intensity),
        showsHighlight: self.showHighlight,
        showsNoise: self.showNoise
      )
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .center(configuration.center)
      configuration.center.size = .fixed(CGSize(width: 360, height: 320))
      configuration.safeAreaPolicy = .containerRespectsSafeArea
      configuration.backdropStyle = .dim(alpha: 0.24)
      configuration.cornerRadius = 22
      configuration.shadow.opacity = 0.16
      configuration.shadow.radius = 24
      configuration.contentInsets = .zero

      FKPresentationController.present(
        contentController: content,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(),
        animated: true,
        completion: nil
      )
    }
  }
}

private final class PopupLiquidGlassSurfaceContentViewController: UIViewController {
  private let intensity: CGFloat
  private let showsHighlight: Bool
  private let showsNoise: Bool

  private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private var highlightLayer: CAGradientLayer?
  private var noiseLayer: CALayer?

  init(intensity: CGFloat, showsHighlight: Bool, showsNoise: Bool) {
    self.intensity = min(max(intensity, 0), 1)
    self.showsHighlight = showsHighlight
    self.showsNoise = showsNoise
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    blurView.alpha = intensity
    blurView.frame = view.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(blurView)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.textAlignment = .center
    titleLabel.text = "Liquid Glass Surface"

    let subtitleLabel = UILabel()
    subtitleLabel.font = .preferredFont(forTextStyle: .body)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = "Blur + highlight + noise rendered in the popup panel."

    [titleLabel, subtitleLabel].forEach { stack.addArrangedSubview($0) }
    blurView.contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -20),
      stack.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
    ])

    applyLiquidLayers()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    highlightLayer?.frame = view.bounds
    noiseLayer?.frame = view.bounds
  }

  private func applyLiquidLayers() {
    let isDark = traitCollection.userInterfaceStyle == .dark
    view.backgroundColor = (isDark ? UIColor.black : UIColor.white).withAlphaComponent(0.06 * intensity)

    if showsHighlight {
      let gradient = CAGradientLayer()
      gradient.frame = view.bounds
      gradient.colors = [
        (isDark ? UIColor.white.withAlphaComponent(0.10) : UIColor.white.withAlphaComponent(0.20)).cgColor,
        (isDark ? UIColor.white.withAlphaComponent(0.02) : UIColor.white.withAlphaComponent(0.06)).cgColor,
        (isDark ? UIColor.black.withAlphaComponent(0.10) : UIColor.black.withAlphaComponent(0.08)).cgColor,
      ]
      gradient.locations = [0, 0.45, 1]
      gradient.startPoint = CGPoint(x: 0.1, y: 0.0)
      gradient.endPoint = CGPoint(x: 0.9, y: 1.0)
      view.layer.addSublayer(gradient)
      highlightLayer = gradient
    }

    if showsNoise {
      let noise = CALayer()
      noise.frame = view.bounds
      noise.contents = Self.noiseImage(scale: UIScreen.main.scale)?.cgImage
      noise.contentsGravity = .resizeAspectFill
      noise.opacity = (isDark ? 0.12 : 0.08) * Float(intensity)
      noise.compositingFilter = "overlayBlendMode"
      view.layer.addSublayer(noise)
      noiseLayer = noise
    }
  }

  private static func noiseImage(scale: CGFloat) -> UIImage? {
    struct Cache { nonisolated(unsafe) static var image: UIImage? }
    if let image = Cache.image { return image }

    let size = CGSize(width: 96, height: 96)
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { ctx in
      let cg = ctx.cgContext
      for _ in 0..<700 {
        let x = CGFloat.random(in: 0..<size.width)
        let y = CGFloat.random(in: 0..<size.height)
        let alpha = CGFloat.random(in: 0...0.18)
        cg.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
        cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
      }
    }
    Cache.image = image
    return image
  }
}
