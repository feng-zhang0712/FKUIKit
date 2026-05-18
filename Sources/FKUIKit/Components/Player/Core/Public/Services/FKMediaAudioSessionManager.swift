import AVFoundation
import Foundation

/// Configures and observes `AVAudioSession` for media playback.
@MainActor
public final class FKMediaAudioSessionManager {

  public static let shared = FKMediaAudioSessionManager()

  private struct InterruptionHandlerEntry {
    weak var owner: AnyObject?
    let handler: (Bool) -> Void
  }

  private var interruptionHandlers: [InterruptionHandlerEntry] = []

  public init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Activates the playback category for media.
  public func activatePlaybackCategory(
    mode: AVAudioSession.Mode = .moviePlayback,
    options: AVAudioSession.CategoryOptions = [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP]
  ) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: mode, options: options)
    try session.setActive(true)
  }

  /// Deactivates the audio session.
  public func deactivate() throws {
    try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  /// Registers an interruption handler for a specific owner (supports multiple coordinators).
  public func setInterruptionHandler(owner: AnyObject, _ handler: @escaping (Bool) -> Void) {
    interruptionHandlers.removeAll { $0.owner === owner }
    interruptionHandlers.append(InterruptionHandlerEntry(owner: owner, handler: handler))
  }

  /// Registers a single global handler (legacy). Prefer ``setInterruptionHandler(owner:_:)``.
  public func setInterruptionHandler(_ handler: @escaping (Bool) -> Void) {
    setInterruptionHandler(owner: self, handler)
  }

  public func removeInterruptionHandler(for owner: AnyObject) {
    interruptionHandlers.removeAll { $0.owner === owner }
  }

  @objc
  private func handleInterruption(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else { return }

    interruptionHandlers.removeAll { $0.owner == nil }
    let shouldResume: Bool
    switch type {
    case .began:
      shouldResume = false
    case .ended:
      let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      shouldResume = options.contains(.shouldResume)
    @unknown default:
      return
    }
    for entry in interruptionHandlers {
      entry.handler(shouldResume)
    }
  }
}
