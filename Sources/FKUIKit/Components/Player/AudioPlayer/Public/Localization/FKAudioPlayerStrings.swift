import Foundation
import ObjectiveC

/// Localized/accessibility strings for audio chrome.
public enum FKAudioPlayerStrings {
  public static let play = NSLocalizedString("fk.audio.play", bundle: .fkAudioPlayer, value: "Play", comment: "")
  public static let pause = NSLocalizedString("fk.audio.pause", bundle: .fkAudioPlayer, value: "Pause", comment: "")
  public static let next = NSLocalizedString("fk.audio.next", bundle: .fkAudioPlayer, value: "Next track", comment: "")
  public static let previous = NSLocalizedString("fk.audio.previous", bundle: .fkAudioPlayer, value: "Previous track", comment: "")
  public static let retry = NSLocalizedString("fk.audio.retry", bundle: .fkAudioPlayer, value: "Retry", comment: "")
  public static let sleepTimer = NSLocalizedString("fk.audio.sleep", bundle: .fkAudioPlayer, value: "Sleep timer", comment: "")
  public static let playbackSpeed = NSLocalizedString("fk.audio.rate", bundle: .fkAudioPlayer, value: "Playback speed", comment: "")
  public static let close = NSLocalizedString("fk.audio.close", bundle: .fkAudioPlayer, value: "Close", comment: "")
}

private final class FKAudioPlayerStringsBundleToken: NSObject {}

private extension Bundle {
  static var fkAudioPlayer: Bundle {
    Bundle(for: FKAudioPlayerStringsBundleToken.self)
  }
}
