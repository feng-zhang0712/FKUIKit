#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIColor {
  /// Creates a color from a 24-bit RGB hex value (for example `0xRRGGBB`).
  convenience init(fk_rgb hex: UInt32, alpha: CGFloat = 1) {
    let r = CGFloat((hex >> 16) & 0xFF) / 255
    let g = CGFloat((hex >> 8) & 0xFF) / 255
    let b = CGFloat(hex & 0xFF) / 255
    self.init(red: r, green: g, blue: b, alpha: alpha)
  }

  /// Parses `#RGB`, `#RRGGBB`, or `#RRGGBBAA` strings (case-insensitive). Returns `nil` when invalid.
  convenience init?(fk_hexString string: String) {
    var s = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if s.hasPrefix("#") {
      s.removeFirst()
    }
    guard s.count == 3 || s.count == 6 || s.count == 8 else { return nil }
    var value: UInt64 = 0
    guard Scanner(string: s).scanHexInt64(&value) else { return nil }

    let a: CGFloat
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat

    switch s.count {
    case 3:
      a = 1
      let r4 = Int((value >> 8) & 0xF)
      let g4 = Int((value >> 4) & 0xF)
      let b4 = Int(value & 0xF)
      r = CGFloat((r4 << 4) | r4) / 255
      g = CGFloat((g4 << 4) | g4) / 255
      b = CGFloat((b4 << 4) | b4) / 255
    case 6:
      a = 1
      r = CGFloat((value >> 16) & 0xFF) / 255
      g = CGFloat((value >> 8) & 0xFF) / 255
      b = CGFloat(value & 0xFF) / 255
    case 8:
      // Interpret as `#RRGGBBAA` (alpha last), common for web-style literals.
      r = CGFloat((value >> 24) & 0xFF) / 255
      g = CGFloat((value >> 16) & 0xFF) / 255
      b = CGFloat((value >> 8) & 0xFF) / 255
      a = CGFloat(value & 0xFF) / 255
    default:
      return nil
    }
    self.init(red: r, green: g, blue: b, alpha: a)
  }

  /// Red, green, blue, and alpha in `0...1` when the color is in a compatible color space.
  var fk_rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
    return (r, g, b, a)
  }
}

#endif
