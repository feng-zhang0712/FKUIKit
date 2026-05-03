import Foundation

enum AnchoredDropdownExampleLogHelpers {
  static func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: Date())
  }
}
