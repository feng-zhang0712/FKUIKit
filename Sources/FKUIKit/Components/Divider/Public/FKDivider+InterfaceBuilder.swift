import UIKit

// MARK: - Interface Builder

public extension FKDivider {
  /// `0` horizontal, `1` vertical.
  @IBInspectable
  var ibDirection: Int {
    get { configuration.direction.rawValue }
    set { configuration.direction = FKDividerDirection(rawValue: newValue) ?? .horizontal }
  }

  /// `0` solid, `1` dashed.
  @IBInspectable
  var ibLineStyle: Int {
    get { configuration.lineStyle.rawValue }
    set { configuration.lineStyle = FKDividerLineStyle(rawValue: newValue) ?? .solid }
  }

  @IBInspectable
  var ibThickness: CGFloat {
    get { configuration.thickness }
    set { configuration.thickness = max(0.5, newValue) }
  }

  @IBInspectable
  var ibColor: UIColor {
    get { configuration.color }
    set { configuration.color = newValue }
  }

  @IBInspectable
  var ibInsetLeft: CGFloat {
    get { configuration.contentInsets.left }
    set { configuration.contentInsets.left = max(0, newValue) }
  }

  @IBInspectable
  var ibInsetRight: CGFloat {
    get { configuration.contentInsets.right }
    set { configuration.contentInsets.right = max(0, newValue) }
  }

  @IBInspectable
  var ibInsetTop: CGFloat {
    get { configuration.contentInsets.top }
    set { configuration.contentInsets.top = max(0, newValue) }
  }

  @IBInspectable
  var ibInsetBottom: CGFloat {
    get { configuration.contentInsets.bottom }
    set { configuration.contentInsets.bottom = max(0, newValue) }
  }

  @IBInspectable
  var ibPixelPerfect: Bool {
    get { configuration.isPixelPerfect }
    set { configuration.isPixelPerfect = newValue }
  }

  @IBInspectable
  var ibShowsGradient: Bool {
    get { configuration.showsGradient }
    set { configuration.showsGradient = newValue }
  }

  @IBInspectable
  var ibGradientStartColor: UIColor {
    get { configuration.gradientStartColor }
    set { configuration.gradientStartColor = newValue }
  }

  @IBInspectable
  var ibGradientEndColor: UIColor {
    get { configuration.gradientEndColor }
    set { configuration.gradientEndColor = newValue }
  }

  /// `0` horizontal gradient axis, `1` vertical.
  @IBInspectable
  var ibGradientDirection: Int {
    get { configuration.gradientDirection.rawValue }
    set { configuration.gradientDirection = FKDividerGradientDirection(rawValue: newValue) ?? .horizontal }
  }

  @IBInspectable
  var ibDashLength: CGFloat {
    get { configuration.dashPattern.first ?? 4 }
    set {
      let gap = configuration.dashPattern.dropFirst().first ?? 3
      configuration.dashPattern = [max(0.1, newValue), max(0.1, gap)]
    }
  }

  @IBInspectable
  var ibDashGap: CGFloat {
    get { configuration.dashPattern.dropFirst().first ?? 3 }
    set {
      let length = configuration.dashPattern.first ?? 4
      configuration.dashPattern = [max(0.1, length), max(0.1, newValue)]
    }
  }
}
