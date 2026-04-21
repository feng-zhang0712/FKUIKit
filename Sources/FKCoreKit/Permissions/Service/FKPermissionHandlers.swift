import Foundation

/// Fallback handler used on unsupported platforms or unavailable capabilities.
@MainActor
class FKUnavailablePermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind

  init(kind: FKPermissionKind) {
    self.kind = kind
  }

  func currentStatus() async -> FKPermissionStatus { .deviceDisabled }

  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    FKPermissionResult(kind: kind, status: .deviceDisabled, error: .unavailable)
  }
}

#if os(iOS)
import AVFoundation
import AppTrackingTransparency
import CoreBluetooth
import EventKit
import MediaPlayer
import Photos
import Speech
import UserNotifications

/// Handles camera permission via `AVCaptureDevice`.
@MainActor
final class FKCameraPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind = .camera
  func currentStatus() async -> FKPermissionStatus {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorized: return .authorized
    @unknown default: return .restricted
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let granted = await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: .video) { continuation.resume(returning: $0) }
    }
    return FKPermissionResult(kind: kind, status: granted ? .authorized : .denied)
  }
}

/// Handles photo library permission with read/add-only access level mapping.
@MainActor
final class FKPhotoPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind
  init(kind: FKPermissionKind) { self.kind = kind }
  func currentStatus() async -> FKPermissionStatus {
    let status: PHAuthorizationStatus
    if #available(iOS 14.0, *) {
      let level: PHAccessLevel = kind == .photoLibraryAddOnly ? .addOnly : .readWrite
      status = PHPhotoLibrary.authorizationStatus(for: level)
    } else {
      status = PHPhotoLibrary.authorizationStatus()
    }
    return map(status)
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let status: PHAuthorizationStatus
    if #available(iOS 14.0, *) {
      let level: PHAccessLevel = kind == .photoLibraryAddOnly ? .addOnly : .readWrite
      status = await withCheckedContinuation { continuation in
        PHPhotoLibrary.requestAuthorization(for: level) { continuation.resume(returning: $0) }
      }
    } else {
      status = await withCheckedContinuation { continuation in
        PHPhotoLibrary.requestAuthorization { continuation.resume(returning: $0) }
      }
    }
    return FKPermissionResult(kind: kind, status: map(status))
  }
  private func map(_ status: PHAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorized: return .authorized
    case .limited: return .limited
    @unknown default: return .restricted
    }
  }
}

/// Handles microphone recording permission via `AVAudioSession`.
@MainActor
final class FKMicrophonePermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind = .microphone
  func currentStatus() async -> FKPermissionStatus {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .undetermined: return .notDetermined
    case .denied: return .denied
    case .granted: return .authorized
    @unknown default: return .restricted
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let granted = await withCheckedContinuation { continuation in
      AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
    }
    return FKPermissionResult(kind: kind, status: granted ? .authorized : .denied)
  }
}

/// Handles push notification authorization via `UNUserNotificationCenter`.
@MainActor
final class FKNotificationPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind = .notifications
  func currentStatus() async -> FKPermissionStatus {
    await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        switch settings.authorizationStatus {
        case .notDetermined: continuation.resume(returning: .notDetermined)
        case .denied: continuation.resume(returning: .denied)
        case .authorized: continuation.resume(returning: .authorized)
        case .provisional: continuation.resume(returning: .provisional)
        case .ephemeral: continuation.resume(returning: .ephemeral)
        @unknown default: continuation.resume(returning: .restricted)
        }
      }
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let granted = await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        continuation.resume(returning: granted)
      }
    }
    return FKPermissionResult(kind: kind, status: granted ? .authorized : await currentStatus())
  }
}

/// Handles Bluetooth authorization using `CBCentralManager`.
@MainActor
final class FKBluetoothPermissionHandler: NSObject, FKPermissionHandling, @preconcurrency CBCentralManagerDelegate {
  let kind: FKPermissionKind = .bluetooth
  private var centralManager: CBCentralManager?
  private var continuation: CheckedContinuation<FKPermissionResult, Never>?
  func currentStatus() async -> FKPermissionStatus {
    switch CBManager.authorization {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .allowedAlways: return .authorized
    @unknown default: return .restricted
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    // Return immediately if user has already made a choice.
    if await currentStatus() != .notDetermined {
      return FKPermissionResult(kind: kind, status: await currentStatus())
    }
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
  }
  nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // Capture value snapshots before crossing actor boundary to avoid data-race warnings.
    let centralState = central.state
    let authorization = CBManager.authorization
    Task { @MainActor in
      guard let continuation = self.continuation else { return }
      guard authorization != .notDetermined else { return }
      self.continuation = nil
      let status: FKPermissionStatus = (centralState == .poweredOff || centralState == .unsupported) ? .deviceDisabled : (authorization == .allowedAlways ? .authorized : .denied)
      continuation.resume(returning: FKPermissionResult(kind: self.kind, status: status))
    }
  }
}

/// Handles calendar and reminders permission via `EKEventStore`.
@MainActor
final class FKEventPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind
  private let store = EKEventStore()
  init(kind: FKPermissionKind) { self.kind = kind }
  func currentStatus() async -> FKPermissionStatus {
    let entity: EKEntityType = kind == .reminders ? .reminder : .event
    switch EKEventStore.authorizationStatus(for: entity) {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorized, .fullAccess, .writeOnly: return .authorized
    @unknown default: return .restricted
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let entity: EKEntityType = kind == .reminders ? .reminder : .event
    let granted = await withCheckedContinuation { continuation in
      store.requestAccess(to: entity) { granted, _ in continuation.resume(returning: granted) }
    }
    return FKPermissionResult(kind: kind, status: granted ? .authorized : .denied)
  }
}

/// Handles Apple Music / media library authorization.
@MainActor
final class FKMediaLibraryPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind = .mediaLibrary
  func currentStatus() async -> FKPermissionStatus {
    switch MPMediaLibrary.authorizationStatus() {
    case .notDetermined: return .notDetermined
    case .denied: return .denied
    case .restricted: return .restricted
    case .authorized: return .authorized
    @unknown default: return .restricted
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let status = await withCheckedContinuation { continuation in
      MPMediaLibrary.requestAuthorization { continuation.resume(returning: $0) }
    }
    switch status {
    case .notDetermined: return FKPermissionResult(kind: kind, status: .notDetermined)
    case .denied: return FKPermissionResult(kind: kind, status: .denied)
    case .restricted: return FKPermissionResult(kind: kind, status: .restricted)
    case .authorized: return FKPermissionResult(kind: kind, status: .authorized)
    @unknown default: return FKPermissionResult(kind: kind, status: .restricted)
    }
  }
}

/// Handles speech recognition authorization.
@MainActor
final class FKSpeechPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind = .speechRecognition
  func currentStatus() async -> FKPermissionStatus {
    switch SFSpeechRecognizer.authorizationStatus() {
    case .notDetermined: return .notDetermined
    case .denied: return .denied
    case .restricted: return .restricted
    case .authorized: return .authorized
    @unknown default: return .restricted
    }
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    let status = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
    }
    switch status {
    case .notDetermined: return FKPermissionResult(kind: kind, status: .notDetermined)
    case .denied: return FKPermissionResult(kind: kind, status: .denied)
    case .restricted: return FKPermissionResult(kind: kind, status: .restricted)
    case .authorized: return FKPermissionResult(kind: kind, status: .authorized)
    @unknown default: return FKPermissionResult(kind: kind, status: .restricted)
    }
  }
}

/// Handles App Tracking Transparency permission.
@MainActor
final class FKAppTrackingPermissionHandler: FKPermissionHandling {
  let kind: FKPermissionKind = .appTracking
  func currentStatus() async -> FKPermissionStatus {
    if #available(iOS 14.0, *) {
      switch ATTrackingManager.trackingAuthorizationStatus {
      case .notDetermined: return .notDetermined
      case .restricted: return .restricted
      case .denied: return .denied
      case .authorized: return .authorized
      @unknown default: return .restricted
      }
    }
    return .authorized
  }
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    if #available(iOS 14.0, *) {
      let status = await withCheckedContinuation { continuation in
        ATTrackingManager.requestTrackingAuthorization { continuation.resume(returning: $0) }
      }
      switch status {
      case .notDetermined: return FKPermissionResult(kind: kind, status: .notDetermined)
      case .restricted: return FKPermissionResult(kind: kind, status: .restricted)
      case .denied: return FKPermissionResult(kind: kind, status: .denied)
      case .authorized: return FKPermissionResult(kind: kind, status: .authorized)
      @unknown default: return FKPermissionResult(kind: kind, status: .restricted)
      }
    }
    return FKPermissionResult(kind: kind, status: .authorized)
  }
}

#else
@MainActor final class FKCameraPermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .camera) } }
@MainActor final class FKPhotoPermissionHandler: FKUnavailablePermissionHandler { override init(kind: FKPermissionKind) { super.init(kind: kind) } }
@MainActor final class FKMicrophonePermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .microphone) } }
@MainActor final class FKNotificationPermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .notifications) } }
@MainActor final class FKBluetoothPermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .bluetooth) } }
@MainActor final class FKEventPermissionHandler: FKUnavailablePermissionHandler { override init(kind: FKPermissionKind) { super.init(kind: kind) } }
@MainActor final class FKMediaLibraryPermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .mediaLibrary) } }
@MainActor final class FKSpeechPermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .speechRecognition) } }
@MainActor final class FKAppTrackingPermissionHandler: FKUnavailablePermissionHandler { init() { super.init(kind: .appTracking) } }
#endif
