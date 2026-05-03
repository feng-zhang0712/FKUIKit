import UIKit

/// Hairline-friendly separator for UIKit lists, cards, and toolbars.
///
/// Set ``defaultConfiguration`` at launch for app-wide styling; each view copies that value until you replace ``configuration``.
@IBDesignable
@MainActor
public final class FKDivider: UIView {
  /// Baseline copied by `init()` and by `UIView.fk_addDivider(at:configuration:margin:)` when you omit a configuration.
  public static var defaultConfiguration = FKDividerConfiguration()

  /// Current style; assigning triggers layout and refreshes dynamic colors on the next layout pass.
  public var configuration: FKDividerConfiguration = FKDivider.defaultConfiguration {
    didSet {
      invalidateIntrinsicContentSize()
      setNeedsLayout()
    }
  }

  private let lineLayer = CAShapeLayer()
  private let gradientLayer = CAGradientLayer()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a divider with an explicit configuration (copied into ``configuration``).
  public convenience init(configuration: FKDividerConfiguration) {
    self.init(frame: .zero)
    self.configuration = configuration
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    updateLayers()
  }

  /// Non-axis dimension equals resolved stroke thickness so `UIStackView` can size hairlines without extra constraints.
  public override var intrinsicContentSize: CGSize {
    let t = resolvedThickness()
    switch configuration.direction {
    case .horizontal:
      return CGSize(width: UIView.noIntrinsicMetric, height: t)
    case .vertical:
      return CGSize(width: t, height: UIView.noIntrinsicMetric)
    }
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateLayers()
  }

  private func commonInit() {
    isUserInteractionEnabled = false
    backgroundColor = .clear
    layer.addSublayer(gradientLayer)
    layer.addSublayer(lineLayer)
    lineLayer.fillColor = UIColor.clear.cgColor
    lineLayer.lineCap = .round
  }

  private func updateLayers() {
    let thickness = resolvedThickness()
    let path = UIBezierPath()
    let b = bounds

    switch configuration.direction {
    case .horizontal:
      if let seg = FKDividerGeometry.horizontalSegment(in: b, contentInsets: configuration.contentInsets) {
        path.move(to: CGPoint(x: seg.x1, y: seg.y))
        path.addLine(to: CGPoint(x: seg.x2, y: seg.y))
      }
    case .vertical:
      if let seg = FKDividerGeometry.verticalSegment(in: b, contentInsets: configuration.contentInsets) {
        path.move(to: CGPoint(x: seg.x, y: seg.y1))
        path.addLine(to: CGPoint(x: seg.x, y: seg.y2))
      }
    }

    lineLayer.path = path.cgPath
    lineLayer.frame = b
    lineLayer.lineWidth = thickness
    lineLayer.lineDashPattern = configuration.lineStyle == .dashed ? configuration.dashPatternNumbers() : nil

    if configuration.showsGradient {
      lineLayer.strokeColor = UIColor.white.cgColor
      gradientLayer.isHidden = false
      gradientLayer.frame = b
      gradientLayer.colors = [
        configuration.gradientStartColor.resolvedColor(with: traitCollection).cgColor,
        configuration.gradientEndColor.resolvedColor(with: traitCollection).cgColor,
      ]
      let rtl = traitCollection.layoutDirection == .rightToLeft
      switch configuration.gradientDirection {
      case .horizontal:
        if rtl {
          gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
          gradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
        } else {
          gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
          gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        }
      case .vertical:
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
      }
      gradientLayer.mask = lineLayer
    } else {
      gradientLayer.mask = nil
      gradientLayer.isHidden = true
      lineLayer.strokeColor = configuration.color.resolvedColor(with: traitCollection).cgColor
    }
  }

  private func resolvedThickness() -> CGFloat {
    guard configuration.isPixelPerfect else { return configuration.thickness }
    let scale = window?.screen.scale ?? UIScreen.main.scale
    return max(1 / scale, 0.5 / scale)
  }
}
