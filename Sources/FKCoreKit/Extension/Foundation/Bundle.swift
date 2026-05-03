import Foundation

public extension Bundle {
  /// Value of `CFBundleShortVersionString` when present.
  var fk_shortVersionString: String {
    (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
  }

  /// Value of `CFBundleVersion` when present.
  var fk_buildVersionString: String {
    (infoDictionary?["CFBundleVersion"] as? String) ?? "0"
  }

  /// Combined `"short (build)"` version label.
  var fk_versionLabel: String {
    "\(fk_shortVersionString) (\(fk_buildVersionString))"
  }

  /// Human-readable bundle name (`CFBundleDisplayName` falling back to `CFBundleName`).
  var fk_displayName: String {
    if let name = infoDictionary?["CFBundleDisplayName"] as? String, !name.isEmpty {
      return name
    }
    return (infoDictionary?["CFBundleName"] as? String) ?? ""
  }
}
