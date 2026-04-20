//
// FKMultiPickerManager.swift
//
// Global defaults manager for FKMultiPicker.
//

import Foundation

/// Global defaults container.
@MainActor
public final class FKMultiPickerManager {
  /// Shared singleton.
  public static let shared = FKMultiPickerManager()
  /// Global default configuration applied by convenience APIs.
  ///
  /// Override this value during app bootstrap to provide a consistent visual style
  /// for all picker instances created with convenience methods.
  public var defaultConfiguration = FKMultiPickerConfiguration()

  /// Creates the singleton manager.
  private init() {}
}
