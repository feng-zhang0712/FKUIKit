#if canImport(UIKit)
import UIKit

public extension UIDevice {
  /// Low-level machine identifier from `uname` (for example `iPhone15,2`).
  var fk_machineIdentifier: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { partialResult, element in
      guard let byte = element.value as? Int8, byte != 0 else { return }
      partialResult.append(Character(UnicodeScalar(UInt8(bitPattern: byte))))
    }
  }

  /// `true` when running an iOS simulator.
  var fk_isSimulator: Bool {
    #if targetEnvironment(simulator)
      true
    #else
      false
    #endif
  }
}

#endif
