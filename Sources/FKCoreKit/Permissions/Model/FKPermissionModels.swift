import Foundation

/// Supported permission domains in FKPermissions.
public enum FKPermissionKind: Hashable, Sendable {
  case camera
  case photoLibraryRead
  case photoLibraryAddOnly
  case microphone
  case locationWhenInUse
  case locationAlways
  case locationTemporaryFullAccuracy
  case notifications
  case bluetooth
  case calendar
  case reminders
  case mediaLibrary
  case speechRecognition
  case appTracking
}

/// Unified authorization states mapped from Apple frameworks.
public enum FKPermissionStatus: Sendable, Equatable {
  case notDetermined
  case authorized
  case denied
  case restricted
  case limited
  case provisional
  case ephemeral
  case deviceDisabled
}

/// Unified error type for permission requests.
public enum FKPermissionError: Error, Sendable, Equatable {
  /// User cancelled the pre-permission guide dialog.
  case prePromptCancelled
  /// The capability is unavailable on current device or system version.
  case unavailable
  /// A custom message for unsupported flows.
  case custom(String)
}

/// Customizable pre-permission guide content.
public struct FKPermissionPrePrompt: Sendable, Equatable, Hashable {
  public let title: String
  public let message: String
  public let confirmTitle: String
  public let cancelTitle: String

  public init(
    title: String,
    message: String,
    confirmTitle: String = "Continue",
    cancelTitle: String = "Not now"
  ) {
    self.title = title
    self.message = message
    self.confirmTitle = confirmTitle
    self.cancelTitle = cancelTitle
  }
}

/// Input model for a permission request action.
public struct FKPermissionRequest: Sendable, Hashable {
  public let kind: FKPermissionKind
  public let prePrompt: FKPermissionPrePrompt?
  /// Purpose key used by temporary full-accuracy location request on iOS 14+.
  public let temporaryLocationPurposeKey: String?

  public init(
    kind: FKPermissionKind,
    prePrompt: FKPermissionPrePrompt? = nil,
    temporaryLocationPurposeKey: String? = nil
  ) {
    self.kind = kind
    self.prePrompt = prePrompt
    self.temporaryLocationPurposeKey = temporaryLocationPurposeKey
  }
}

/// Output model for a single permission request.
public struct FKPermissionResult: Sendable, Equatable {
  public let kind: FKPermissionKind
  public let status: FKPermissionStatus
  public let error: FKPermissionError?

  public init(kind: FKPermissionKind, status: FKPermissionStatus, error: FKPermissionError? = nil) {
    self.kind = kind
    self.status = status
    self.error = error
  }

  /// Whether the permission request ends with an accessible status.
  public var isGranted: Bool {
    switch status {
    case .authorized, .limited, .provisional, .ephemeral:
      return true
    case .notDetermined, .denied, .restricted, .deviceDisabled:
      return false
    }
  }
}
