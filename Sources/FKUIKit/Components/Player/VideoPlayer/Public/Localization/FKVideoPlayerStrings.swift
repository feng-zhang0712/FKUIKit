import Foundation
import ObjectiveC

/// Localized/accessibility strings for video chrome (Phase 3 i18n baseline).
public enum FKVideoPlayerStrings {
  public static let play = NSLocalizedString("fk.video.play", bundle: .fkVideoPlayer, value: "Play", comment: "")
  public static let pause = NSLocalizedString("fk.video.pause", bundle: .fkVideoPlayer, value: "Pause", comment: "")
  public static let loading = NSLocalizedString("fk.video.loading", bundle: .fkVideoPlayer, value: "Loading", comment: "")
  public static let retry = NSLocalizedString("fk.video.retry", bundle: .fkVideoPlayer, value: "Retry", comment: "")
  public static let fullscreen = NSLocalizedString("fk.video.fullscreen", bundle: .fkVideoPlayer, value: "Full screen", comment: "")
  public static let settings = NSLocalizedString("fk.video.settings", bundle: .fkVideoPlayer, value: "Playback settings", comment: "")
  public static let live = NSLocalizedString("fk.video.live", bundle: .fkVideoPlayer, value: "Live", comment: "")
  public static let close = NSLocalizedString("fk.video.close", bundle: .fkVideoPlayer, value: "Close", comment: "")
  public static let progress = NSLocalizedString("fk.video.progress", bundle: .fkVideoPlayer, value: "Playback progress", comment: "")
  public static let screenCaptureBlocked = NSLocalizedString(
    "fk.video.screen_capture",
    bundle: .fkVideoPlayer,
    value: "Screen recording is not allowed",
    comment: ""
  )
}

private final class FKVideoPlayerStringsBundleToken: NSObject {}

private extension Bundle {
  static var fkVideoPlayer: Bundle {
    Bundle(for: FKVideoPlayerStringsBundleToken.self)
  }
}
