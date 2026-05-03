import Foundation

public extension ProcessInfo {
  /// Human-readable thermal state label for logging and diagnostics.
  var fk_thermalStateDescription: String {
    switch thermalState {
    case .nominal:
      return "nominal"
    case .fair:
      return "fair"
    case .serious:
      return "serious"
    case .critical:
      return "critical"
    @unknown default:
      return "unknown"
    }
  }

  /// `true` when the app is running in a SwiftUI preview or similar preview environment when reported by the system.
  var fk_isRunningInPreview: Bool {
    environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }
}
