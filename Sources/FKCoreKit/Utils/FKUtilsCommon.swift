import AudioToolbox
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

/// Static common utility helpers.
public enum FKUtilsCommon {
  #if canImport(AVFoundation)
  /// Thread-safe audio player storage to avoid shared mutable global state warnings.
  private final class AudioPlayerStore: @unchecked Sendable {
    private let lock = NSLock()
    private var player: AVAudioPlayer?

    func set(_ player: AVAudioPlayer?) {
      lock.lock()
      defer { lock.unlock() }
      self.player = player
    }

    func get() -> AVAudioPlayer? {
      lock.lock()
      defer { lock.unlock() }
      return player
    }
  }

  private static let audioStore = AudioPlayerStore()
  #endif

  /// Returns home directory URL.
  public static func homeDirectory() -> URL {
    URL(fileURLWithPath: NSHomeDirectory())
  }

  /// Returns documents directory URL.
  public static func documentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? homeDirectory()
  }

  /// Returns caches directory URL.
  public static func cachesDirectory() -> URL {
    FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? homeDirectory()
  }

  /// Returns temporary directory URL.
  public static func temporaryDirectory() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
  }

  /// Returns file size in bytes.
  public static func fileSize(at url: URL) -> Int64 {
    let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
    if values?.isDirectory == true {
      return folderSize(at: url)
    }
    return Int64(values?.fileSize ?? 0)
  }

  /// Opens App Store page for app id.
  public static func openAppStore(appID: String) {
    openURL("itms-apps://itunes.apple.com/app/id\(appID)")
  }

  /// Opens application settings page.
  public static func openSettings() {
    #if canImport(UIKit)
    openURL(UIApplication.openSettingsURLString)
    #endif
  }

  /// Starts a phone call if supported.
  public static func call(phoneNumber: String) {
    openURL("tel://\(phoneNumber)")
  }

  /// Opens message compose URL.
  public static func sms(phoneNumber: String) {
    openURL("sms://\(phoneNumber)")
  }

  /// Opens mail compose URL.
  public static func email(address: String, subject: String? = nil) {
    var text = "mailto:\(address)"
    if let subject, !subject.isEmpty {
      text += "?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)"
    }
    openURL(text)
  }

  /// Triggers vibration feedback.
  public static func vibrate() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }

  /// Plays a bundled sound file.
  public static func playSound(named fileName: String, fileExtension: String) {
    #if canImport(AVFoundation)
    guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else { return }
    let player = try? AVAudioPlayer(contentsOf: url)
    player?.prepareToPlay()
    player?.play()
    audioStore.set(player)
    #endif
  }

  /// Returns whether object is nil or empty-like.
  public static func isNilOrEmpty(_ value: Any?) -> Bool {
    switch value {
    case nil:
      return true
    case let text as String:
      return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case let array as [Any]:
      return array.isEmpty
    case let dictionary as [AnyHashable: Any]:
      return dictionary.isEmpty
    case _ as NSNull:
      return true
    default:
      return false
    }
  }

  /// Safely converts value to string.
  public static func toString(_ value: Any?) -> String? {
    guard let value else { return nil }
    if let string = value as? String { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return "\(value)"
  }

  /// Safely converts value to integer.
  public static func toInt(_ value: Any?) -> Int? {
    switch value {
    case let int as Int:
      return int
    case let string as String:
      return Int(string)
    case let number as NSNumber:
      return number.intValue
    default:
      return nil
    }
  }

  /// Safely converts value to double.
  public static func toDouble(_ value: Any?) -> Double? {
    switch value {
    case let double as Double:
      return double
    case let float as Float:
      return Double(float)
    case let string as String:
      return Double(string)
    case let number as NSNumber:
      return number.doubleValue
    default:
      return nil
    }
  }

  /// Executes closure and catches thrown errors.
  public static func safe<T>(_ action: () throws -> T) -> Result<T, Error> {
    do { return .success(try action()) }
    catch { return .failure(error) }
  }

  /// Computes recursive folder size.
  private static func folderSize(at url: URL) -> Int64 {
    guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey]) else {
      return 0
    }
    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
      let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
      if values?.isDirectory != true {
        total += Int64(values?.fileSize ?? 0)
      }
    }
    return total
  }

  /// Opens URL string on main thread.
  private static func openURL(_ string: String) {
    #if canImport(UIKit)
    guard let url = URL(string: string) else { return }
    let execute = {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    if Thread.isMainThread {
      execute()
    } else {
      DispatchQueue.main.async(execute: execute)
    }
    #endif
  }
}
