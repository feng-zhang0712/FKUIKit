import Foundation

/// Unified namespace for FK utility modules.
public enum FKUtils {}

public extension FKUtils {
  /// Date and time helpers.
  typealias DateTime = FKUtilsDate
  /// Regex and validation helpers.
  typealias Regex = FKUtilsRegex
  /// Number formatting helpers.
  typealias Number = FKUtilsNumber
  /// String processing helpers.
  typealias String = FKUtilsString
  /// Device information helpers.
  typealias Device = FKUtilsDevice
  /// Collection helpers.
  typealias Collection = FKUtilsCollection
  /// Common helpers.
  typealias Common = FKUtilsCommon
}

#if canImport(UIKit)
public extension FKUtils {
  /// UI helpers.
  typealias UI = FKUtilsUI
  /// Image helpers.
  typealias Image = FKUtilsImage
}
#endif
