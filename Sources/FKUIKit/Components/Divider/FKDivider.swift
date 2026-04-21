import UIKit

/// Lightweight, reusable divider view for UIKit.
@IBDesignable
@MainActor
public final class FKDivider: UIView {
  /// Divider configuration.
  public var configuration: FKDividerConfiguration = FKDividerManager.shared.defaultConfiguration {
    didSet { setNeedsLayout() }
  }

  private let lineLayer = CAShapeLayer()
  private let gradientLayer = CAGradientLayer()

  /// Creates an empty divider with global default configuration.
  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  /// Creates a divider from Interface Builder.
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a divider with an explicit configuration.
  ///
  /// - Parameter configuration: Initial divider configuration.
  public convenience init(configuration: FKDividerConfiguration) {
    self.init(frame: .zero)
    self.configuration = configuration
    setNeedsLayout()
  }

  /// Applies a configuration and refreshes rendering.
  ///
  /// - Parameter configuration: New divider configuration.
  public func apply(configuration: FKDividerConfiguration) {
    self.configuration = configuration
  }

  /// Lays out subviews and updates divider path/layers.
  public override func layoutSubviews() {
    super.layoutSubviews()
    updateLayers()
  }

  /// Responds to trait changes (for example dark mode) and refreshes dynamic colors.
  ///
  /// - Parameter previousTraitCollection: Previous trait collection.
  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Refresh CGColor-backed layers because dynamic colors resolve against the current traits.
    updateLayers()
  }

  private func commonInit() {
    // Divider is a purely decorative element; disable interaction and render with shape layers.
    isUserInteractionEnabled = false
    backgroundColor = .clear
    layer.addSublayer(gradientLayer)
    layer.addSublayer(lineLayer)
    lineLayer.fillColor = UIColor.clear.cgColor
    lineLayer.lineCap = .round
  }

  private func updateLayers() {
    // Recompute stroke geometry every layout pass to stay correct under Auto Layout and rotation.
    let thickness = resolvedThickness()
    let path = UIBezierPath()

    switch configuration.direction {
    case .horizontal:
      // Horizontal stroke is centered vertically and optionally shortened by left/right insets.
      let y = bounds.midY
      let x1 = min(max(0, configuration.contentInsets.left), bounds.width)
      let x2 = max(0, bounds.width - max(0, configuration.contentInsets.right))
      path.move(to: CGPoint(x: x1, y: y))
      path.addLine(to: CGPoint(x: x2, y: y))
    case .vertical:
      // Vertical stroke is centered horizontally and optionally shortened by top/bottom insets.
      let x = bounds.midX
      let y1 = min(max(0, configuration.contentInsets.top), bounds.height)
      let y2 = max(0, bounds.height - max(0, configuration.contentInsets.bottom))
      path.move(to: CGPoint(x: x, y: y1))
      path.addLine(to: CGPoint(x: x, y: y2))
    }

    lineLayer.path = path.cgPath
    lineLayer.frame = bounds
    lineLayer.lineWidth = thickness
    lineLayer.lineDashPattern = configuration.lineStyle == .dashed ? configuration.dashPattern : nil

    if configuration.showsGradient {
      // Use the line layer as gradient mask so dashed/solid behaviors remain identical.
      lineLayer.strokeColor = UIColor.white.cgColor
      gradientLayer.isHidden = false
      gradientLayer.frame = bounds
      gradientLayer.colors = [
        configuration.gradientStartColor.resolvedColor(with: traitCollection).cgColor,
        configuration.gradientEndColor.resolvedColor(with: traitCollection).cgColor,
      ]
      switch configuration.gradientDirection {
      case .horizontal:
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
      case .vertical:
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
      }
      gradientLayer.mask = lineLayer
    } else {
      // Disable gradient path and render plain color stroke.
      gradientLayer.mask = nil
      gradientLayer.isHidden = true
      lineLayer.strokeColor = configuration.color.resolvedColor(with: traitCollection).cgColor
    }
  }

  private func resolvedThickness() -> CGFloat {
    // Pixel-perfect mode forces 1 physical pixel regardless of logical point size.
    guard configuration.isPixelPerfect else { return configuration.thickness }
    let scale = window?.screen.scale ?? UIScreen.main.scale
    return max(1 / scale, 0.5 / scale)
  }
}

// MARK: - Interface Builder Bridge

public extension FKDivider {
  /// IB bridge for direction (`0: horizontal`, `1: vertical`).
  @IBInspectable
  var ibDirection: Int {
    get { configuration.direction.rawValue }
    set { configuration.direction = FKDividerDirection(rawValue: newValue) ?? .horizontal }
  }

  /// IB bridge for line style (`0: solid`, `1: dashed`).
  @IBInspectable
  var ibLineStyle: Int {
    get { configuration.lineStyle.rawValue }
    set { configuration.lineStyle = FKDividerLineStyle(rawValue: newValue) ?? .solid }
  }

  /// IB bridge for thickness.
  @IBInspectable
  var ibThickness: CGFloat {
    get { configuration.thickness }
    set { configuration.thickness = max(0.5, newValue) }
  }

  /// IB bridge for divider color.
  @IBInspectable
  var ibColor: UIColor {
    get { configuration.color }
    set { configuration.color = newValue }
  }

  /// IB bridge for left inset.
  @IBInspectable
  var ibInsetLeft: CGFloat {
    get { configuration.contentInsets.left }
    set { configuration.contentInsets.left = max(0, newValue) }
  }

  /// IB bridge for right inset.
  @IBInspectable
  var ibInsetRight: CGFloat {
    get { configuration.contentInsets.right }
    set { configuration.contentInsets.right = max(0, newValue) }
  }

  /// IB bridge for top inset.
  @IBInspectable
  var ibInsetTop: CGFloat {
    get { configuration.contentInsets.top }
    set { configuration.contentInsets.top = max(0, newValue) }
  }

  /// IB bridge for bottom inset.
  @IBInspectable
  var ibInsetBottom: CGFloat {
    get { configuration.contentInsets.bottom }
    set { configuration.contentInsets.bottom = max(0, newValue) }
  }

  /// IB bridge for pixel-perfect rendering.
  @IBInspectable
  var ibPixelPerfect: Bool {
    get { configuration.isPixelPerfect }
    set { configuration.isPixelPerfect = newValue }
  }

  /// IB bridge for gradient enable.
  @IBInspectable
  var ibShowsGradient: Bool {
    get { configuration.showsGradient }
    set { configuration.showsGradient = newValue }
  }

  /// IB bridge for gradient start color.
  @IBInspectable
  var ibGradientStartColor: UIColor {
    get { configuration.gradientStartColor }
    set { configuration.gradientStartColor = newValue }
  }

  /// IB bridge for gradient end color.
  @IBInspectable
  var ibGradientEndColor: UIColor {
    get { configuration.gradientEndColor }
    set { configuration.gradientEndColor = newValue }
  }

  /// IB bridge for gradient direction (`0: horizontal`, `1: vertical`).
  @IBInspectable
  var ibGradientDirection: Int {
    get { configuration.gradientDirection.rawValue }
    set { configuration.gradientDirection = FKDividerGradientDirection(rawValue: newValue) ?? .horizontal }
  }

  /// IB bridge for dashed segment length.
  @IBInspectable
  var ibDashLength: CGFloat {
    get { CGFloat(truncating: configuration.dashPattern.first ?? 4) }
    set {
      let gap = CGFloat(truncating: configuration.dashPattern.dropFirst().first ?? 3)
      configuration.dashPattern = [NSNumber(value: Double(max(0.1, newValue))), NSNumber(value: Double(max(0.1, gap)))]
    }
  }

  /// IB bridge for dashed gap length.
  @IBInspectable
  var ibDashGap: CGFloat {
    get { CGFloat(truncating: configuration.dashPattern.dropFirst().first ?? 3) }
    set {
      let length = CGFloat(truncating: configuration.dashPattern.first ?? 4)
      configuration.dashPattern = [NSNumber(value: Double(max(0.1, length))), NSNumber(value: Double(max(0.1, newValue)))]
    }
  }
}
