#if canImport(UIKit)
import UIKit

/// Bridges nonisolated FKCoreKit helpers to MainActor-isolated `UIDevice` / `UIScreen` APIs without marking broad protocols `@MainActor`.
enum FKMainActorUIKitBridge {
  nonisolated static func systemVersion() -> String {
    executeOnMain { UIDevice.current.systemVersion }
  }

  nonisolated static func screenBoundsSize() -> CGSize {
    executeOnMain { UIScreen.main.bounds.size }
  }

  nonisolated static func screenScale() -> CGFloat {
    executeOnMain { UIScreen.main.scale }
  }

  nonisolated static func batteryLevel() -> Float {
    executeOnMain {
      UIDevice.current.isBatteryMonitoringEnabled = true
      return UIDevice.current.batteryLevel
    }
  }

  nonisolated static func batteryStateDescription() -> String {
    executeOnMain {
      UIDevice.current.isBatteryMonitoringEnabled = true
      switch UIDevice.current.batteryState {
      case .unknown: return "unknown"
      case .unplugged: return "unplugged"
      case .charging: return "charging"
      case .full: return "full"
      @unknown default: return "unknown"
      }
    }
  }

  nonisolated static func identifierForVendorUUIDString() -> String {
    executeOnMain {
      UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
  }

  private nonisolated static func executeOnMain<T: Sendable>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
      return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
      MainActor.assumeIsolated(body)
    }
  }
}
#endif
