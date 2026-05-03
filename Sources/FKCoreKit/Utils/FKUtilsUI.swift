import Foundation

#if canImport(UIKit)
import UIKit

/// Static UI utility helpers.
@MainActor
public enum FKUtilsUI {
  /// Creates color from hex string such as `#FFAA00`.
  public static func color(hex: String, alpha: CGFloat = 1) -> UIColor {
    let cleaned = hex.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard cleaned.count == 6 || cleaned.count == 8 else { return .clear }
    let value = UInt64(cleaned, radix: 16) ?? 0
    if cleaned.count == 8 {
      let r = CGFloat((value & 0xFF000000) >> 24) / 255.0
      let g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
      let b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
      let a = CGFloat(value & 0x000000FF) / 255.0
      return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(value & 0x0000FF) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: alpha)
  }

  /// Converts color to hex text (`#RRGGBB`).
  public static func hex(from color: UIColor) -> String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
  }

  /// Creates dynamic color by user interface style.
  public static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark ? dark : light
    }
  }

  /// Returns adaptive font by screen width ratio.
  public static func adaptiveFont(size: CGFloat, weight: UIFont.Weight = .regular, baselineWidth: CGFloat = 375) -> UIFont {
    let scale = UIScreen.main.bounds.width / baselineWidth
    return UIFont.systemFont(ofSize: max(8, size * scale), weight: weight)
  }

  /// Converts points to pixels.
  public static func pointsToPixels(_ points: CGFloat, scale: CGFloat? = nil) -> CGFloat {
    points * (scale ?? UIScreen.main.scale)
  }

  /// Converts pixels to points.
  public static func pixelsToPoints(_ pixels: CGFloat, scale: CGFloat? = nil) -> CGFloat {
    let resolvedScale = scale ?? UIScreen.main.scale
    return resolvedScale == 0 ? pixels : pixels / resolvedScale
  }

  /// Applies corner radius to a view.
  public static func applyCornerRadius(_ radius: CGFloat, to view: UIView, clipsToBounds: Bool = true) {
    view.layer.cornerRadius = radius
    view.clipsToBounds = clipsToBounds
  }

  /// Applies shadow style to a view.
  public static func applyShadow(to view: UIView, color: UIColor = .black, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4, opacity: Float = 0.15) {
    view.layer.shadowColor = color.cgColor
    view.layer.shadowOffset = offset
    view.layer.shadowRadius = radius
    view.layer.shadowOpacity = opacity
    view.layer.masksToBounds = false
  }

  /// Adds gradient layer into view.
  @discardableResult
  public static func addGradient(to view: UIView, colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1)) -> CAGradientLayer {
    let gradient = CAGradientLayer()
    gradient.colors = colors.map(\.cgColor)
    gradient.startPoint = startPoint
    gradient.endPoint = endPoint
    gradient.frame = view.bounds
    view.layer.insertSublayer(gradient, at: 0)
    return gradient
  }

  /// Executes block safely on main thread.
  public static func runOnMain(_ block: @escaping @Sendable () -> Void) {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        block()
      }
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  /// Captures a snapshot image from a view.
  public static func screenshot(of view: UIView) -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    return renderer.image { _ in
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
  }
}
#endif
