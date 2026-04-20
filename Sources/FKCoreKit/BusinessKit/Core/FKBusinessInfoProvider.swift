import Foundation
import UIKit

/// Default implementation of ``FKBusinessInfoProviding``.
public final class FKBusinessInfoProvider: FKBusinessInfoProviding, @unchecked Sendable {
  /// Supplies runtime configuration values (channel/environment).
  private let configurationProvider: @Sendable () -> FKBusinessKitConfiguration

  /// Creates an info provider.
  ///
  /// - Parameter configurationProvider: Supplies current configuration.
  public init(configurationProvider: @escaping @Sendable () -> FKBusinessKitConfiguration) {
    self.configurationProvider = configurationProvider
  }

  /// Current application bundle identifier.
  public var bundleID: String {
    Bundle.main.bundleIdentifier ?? ""
  }

  /// Current marketing version from `CFBundleShortVersionString`.
  public var appVersion: String {
    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
  }

  /// Current build number from `CFBundleVersion`.
  public var buildNumber: String {
    (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0"
  }

  /// Current iOS system version.
  public var systemVersion: String {
    UIDevice.current.systemVersion
  }

  /// Current hardware model identifier.
  public var deviceModelIdentifier: String {
    Self.hardwareMachineIdentifier() ?? "unknown"
  }

  /// Current main screen size in points.
  public var screenSize: CGSize {
    UIScreen.main.bounds.size
  }

  /// Current distribution channel from toolkit configuration.
  public var channel: String {
    configurationProvider().channel
  }

  /// Current runtime environment from toolkit configuration.
  public var environment: FKBusinessEnvironment {
    configurationProvider().environment
  }

  /// Resolves hardware identifier from `sysctl` (`hw.machine`).
  ///
  /// - Returns: Device model identifier string, or `nil` if unavailable.
  private static func hardwareMachineIdentifier() -> String? {
    var size: size_t = 0
    guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0 else { return nil }
    var buffer = [CChar](repeating: 0, count: Int(size))
    guard sysctlbyname("hw.machine", &buffer, &size, nil, 0) == 0 else { return nil }
    return String(cString: buffer)
  }
}

