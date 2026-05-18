# FKAudioPlayer

UIKit **audio playback facade** for music, podcasts, and audiobooks. Built on [FKMediaPlayer Core](../Core/README.md) with `presentationMode: .audioOnly` — no video surface. For video or PiP, use [FKVideoPlayer](../VideoPlayer/README.md).

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`
- Background audio capability in the host app (`UIBackgroundModes` → `audio` when needed)

## Architecture

```
FKAudioPlayer
    │  FKAudioQueue, lyrics, mini bar, sleep timer
    ▼
FKMediaPlaybackCoordinator  (presentationMode: .audioOnly, renderTarget: .none)
    ▼
FKAVPlayerEngine / extended engine
```

| Concern | Owner |
|---------|--------|
| Transport, session, Now Playing data | Core |
| Queue modes, UI, lyrics, timers, history | AudioPlayer |

## Features

| Category | Components |
|----------|------------|
| **Playback** | `load`, `loadQueue`, play/pause/stop, seek, rate (0.5x–2x), cross-track fade |
| **Queue** | `FKAudioQueue` — sequential, shuffle, repeat one, repeat all |
| **UI** | `FKAudioPlayerView`, `FKAudioMiniBar`, `FKAudioPlayerViewController`, `FKAudioControlsView` |
| **Lyrics** | LRC via `FKAudioLyricsParser`; plain text fallback; `FKAudioLyricsView` |
| **Podcast** | `FKAudioChapter`, `seekToChapter` |
| **System** | Lock screen / Control Center (Core Now Playing + track skip commands) |
| **Tools** | `FKAudioSleepTimer`, stop-after-current-track |
| **History** | `FKAudioPlayHistoryStore` (default: `FKAudioUserDefaultsPlayHistoryStore`) |
| **CarPlay** | `FKAudioCarPlayCoordinator` (remote skip registration helper) |
| **Extras** | `FKAudioWaveformView`, Watch/Widget snapshot protocols (`FKAudioWatchWidgetBridge`) |
| **SwiftUI** | `FKAudioPlayerSwiftUIView`, `UIView.fk_embedAudioPlayer` |

## Quick start

```swift
import FKUIKit

let player = FKAudioPlayer()
let playerView = FKAudioPlayerView(style: .standard)
view.addSubview(playerView)
player.bind(to: playerView)

let track = FKAudioItem(
  source: .url(audioURL),
  title: "Track",
  artist: "Artist",
  artworkURL: coverURL
)

player.load(track, autoPlay: true)
```

### Queue

```swift
player.loadQueue(tracks, startIndex: 0, autoPlay: true)
player.playNext()
player.playPrevious()
```

### Sleep timer

```swift
player.setSleepTimer(fireDate: Date().addingTimeInterval(30 * 60))
player.setStopAfterCurrentItem(true)
```

### Cross-track fade

```swift
player.configuration.playback.fadeBetweenTracksDuration = 0.8
```

## Key types

| Type | Role |
|------|------|
| `FKAudioPlayer` | Public API; owns coordinator and `FKAudioQueue` |
| `FKAudioItem` | Audio model → `FKMediaItem` |
| `FKAudioQueueMode` | `.sequential`, `.shuffle`, `.repeatOne`, `.repeatAll` |
| `FKAudioPlayerConfiguration` | Core `media`, UI, `FKAudioPlaybackPreferences` |
| `FKAudioPlayerDelegate` | State, time, item/index, lyrics line, finish, fail |

### Queue modes

| Mode | Behavior |
|------|----------|
| `sequential` | Advance until end; then `audioPlayerDidFinish` |
| `shuffle` | Shuffled order; wrap at end |
| `repeatOne` | Same item; coordinator loop `.one` |
| `repeatAll` | Uses Core playlist when multiple items; lock-screen skip via coordinator |

## Configuration

| Preference | Default |
|------------|---------|
| `maxRate` | `2.0` |
| `remembersRatePerItem` | `true` |
| `fadeBetweenTracksDuration` | `nil` |
| `enablesBackgroundPlayback` | `true` |

Artwork: set `FKAudioItem.artworkURL` or `FKAudioUIConfiguration.defaultArtwork`. Embedded ID3 extraction is **not** built in.

## Source layout

```
Player/AudioPlayer/
├── Public/
│   ├── FKAudioPlayer.swift
│   ├── Models/          item, queue, configuration
│   ├── UI/              player view, mini bar, controls, lyrics, waveform
│   ├── Lyrics/          LRC parser, lyric line model
│   ├── Services/        sleep timer, play history, CarPlay helper, QoE
│   └── Bridge/          SwiftUI + UIView helpers
└── Internal/            queue advance, fade, coordinator binding
```

## Limitations

| Topic | Notes |
|-------|--------|
| **Video / PiP / subtitles** | Use `FKVideoPlayer`. |
| **ID3 embedded artwork** | Use `artworkURL` or `defaultArtwork`; no automatic tag parsing. |
| **CarPlay templates** | Coordinator enables skip commands; full CarPlay UI is host-app responsibility. |
| **Streaming SDKs** | No Spotify/Apple Music SDK; bring your own URLs and DRM. |
| **Recorder** | Out of scope. |
| **Extended audio formats** | Routed through Core; register an extended engine factory if needed. |

## Related modules

- [Core](../Core/README.md) — engines and coordinator
- [VideoPlayer](../VideoPlayer/README.md) — video facade

## License

Same as FKKit.
