# FKVideoPlayer

UIKit **video playback facade** built on [FKMediaPlayer Core](../Core/README.md). Use it for on-demand video, live streams, feeds, offline HLS, subtitles, PiP, and fullscreen chrome — not for music/podcast-only apps (see [FKAudioPlayer](../AudioPlayer/README.md)).

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`
- Core playback capabilities (same module)

## Architecture

```
FKVideoPlayer
    │  FKVideoItem, UI, gestures, PiP, subtitles
    ▼
FKMediaPlaybackCoordinator  (presentationMode: .video)
    ▼
FKAVPlayerEngine / extended engine
```

| Concern | Owner |
|---------|--------|
| Play, pause, seek, buffer, engine routing | Core |
| Layer binding, controls, live badge, feed pool | VideoPlayer |

## Features

| Category | Components |
|----------|------------|
| **Playback** | `load`, `load(playlist:)`, play/pause/stop, rate, volume, skip intro/outro, chapters |
| **UI** | `FKVideoPlayerView`, `FKDefaultVideoControlView`, `FKVideoPlayerViewController`, `FKVideoMiniPlayerView` |
| **Live** | `FKVideoLiveBadgeView`, `seekToLiveEdge()`, LL-HLS debug panel (`showsLLHLSDebugPanel`) |
| **Subtitles** | Embedded legible tracks; external **SRT / VTT** via `FKVideoSubtitleParser` |
| **Quality** | HLS peak bitrate, settings menu (speed / tracks) |
| **System** | PiP, AirPlay, screen-capture overlay, Now Playing metadata via Core |
| **Feed** | `FKVideoFeedPlaybackCoordinator`, `FKVideoPlayerPool` |
| **Offline** | `FKVideoOfflineDownloadManager` (HLS download + registry; wired to coordinator on init) |
| **Integrations** | `FKVideoAdPlugin`, `FKVideoQoEReporter`, thumbnail seek (`FKVideoThumbnailProvider`) |
| **SwiftUI** | `FKVideoPlayerSwiftUIView`, `UIView.fk_embedVideoPlayer` |

## Quick start

```swift
import FKUIKit

let player = FKVideoPlayer()
let playerView = FKVideoPlayerView(frame: bounds)
addSubview(playerView)

let item = FKVideoItem(
  source: .url(videoURL),
  title: "Episode 1",
  posterURL: posterURL
)

player.bind(to: playerView)
player.load(item)
player.play()
```

### SwiftUI

```swift
FKVideoPlayerSwiftUIView(player: player)
  .frame(height: 220)
```

### Offline HLS

```swift
let id = player.offlineDownloadManager.startDownload(from: hlsURL, title: "Cached")
// after completion:
if let item = player.offlineDownloadManager.makeOfflineItem(downloadIdentifier: id, title: "Cached") {
  player.load(item)
}
```

### Low-latency HLS

```swift
player.setLowLatencyHLS(enabled: true, liveOffsetSeconds: 3)
player.showsLLHLSDebugPanel = true  // debug overlay on FKVideoPlayerView
```

## Key types

| Type | Role |
|------|------|
| `FKVideoPlayer` | Public API; owns `FKMediaPlaybackCoordinator` |
| `FKVideoItem` | Video model → `FKMediaItem` |
| `FKVideoPlayerConfiguration` | Core `media` + `FKVideoUIConfiguration` |
| `FKVideoPlayerDelegate` | State, time, buffer, finish, fail, fullscreen |
| `FKVideoPlayerControlView` | Replaceable control surface protocol |

### Delegate (excerpt)

```swift
public protocol FKVideoPlayerDelegate: AnyObject {
  func videoPlayer(_ player: FKVideoPlayer, didChangeState: FKMediaPlaybackState)
  func videoPlayer(_ player: FKVideoPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval)
  func videoPlayerDidFinish(_ player: FKVideoPlayer)
  func videoPlayer(_ player: FKVideoPlayer, didFail: FKMediaError)
}
```

## Configuration

`FKVideoPlayerConfiguration.shared` composes Core settings with UI defaults:

| UI setting | Default |
|------------|---------|
| `controlsAutoHideInterval` | `5.0` s |
| `showsRemainingTime` | `false` |
| `gestureSeekSeconds` | `10.0` |
| `allowsPictureInPicture` | `true` |
| `allowsAirPlay` | `true` |
| `aspectFill` | `false` |

Forward DRM, network, and resume options through `configuration.media`.

## Source layout

```
Player/VideoPlayer/
├── Public/
│   ├── FKVideoPlayer.swift
│   ├── Models/          FKVideoItem, playlist, configuration
│   ├── UI/              player view, controls, gestures, mini player
│   ├── Live/            live badge, LL-HLS debug panel
│   ├── Subtitle/        parser (SRT/VTT), subtitle view
│   ├── Feed/            scroll visibility, player pool
│   ├── System/          PiP, AirPlay, SharePlay hook
│   ├── Services/        offline download, QoE, ads
│   └── Bridge/          SwiftUI + UIView helpers
└── Internal/            coordinator binding extensions
```

Do **not** add `Engine/` or `FormatProbe/` here — they belong in Core.

## Limitations

| Topic | Notes |
|-------|--------|
| **Pure audio apps** | Use `FKAudioPlayer`; do not route music-only UX through video APIs. |
| **ASS subtitles** | `FKVideoSubtitleFormat.ass` is declared; parser currently returns no cues (SRT/VTT supported). |
| **SharePlay** | `FKVideoSharePlayCoordinator` is a stub; requires Group Activities in the host app. |
| **Ads** | `FKVideoAdPlugin` is an integration surface; no ad SDK is bundled. |
| **FairPlay** | Configure via `fairPlayContentKeyProvider` / `FKMediaFairPlayDRMPlugin` on the coordinator. |
| **Extended formats** (MKV, RTMP, …) | Require `FKMediaEngineRouter.registerExtendedEngineFactory` or AV fallback. |
| **WebRTC** | Out of scope. |

## Related modules

- [Core](../Core/README.md) — engines, probe, coordinator
- [AudioPlayer](../AudioPlayer/README.md) — audio-only facade

## License

Same as FKKit.
