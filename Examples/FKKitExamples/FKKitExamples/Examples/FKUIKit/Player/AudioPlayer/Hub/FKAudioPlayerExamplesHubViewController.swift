import FKUIKit
import UIKit

/// Lists ``FKAudioPlayer`` example screens grouped by feature area.
final class FKAudioPlayerExamplesHubViewController: UITableViewController {

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private struct DemoItem {
    let title: String
    let subtitle: String
    let factory: () -> UIViewController
  }

  private struct DemoSection {
    let title: String
    let items: [DemoItem]
  }

  private lazy var sections: [DemoSection] = [
    DemoSection(title: "Basics", items: [
      DemoItem(
        title: "Progressive MP3",
        subtitle: "HTTPS file, artwork, default `FKAudioPlayerView` chrome.",
        factory: { FKAudioPlayerMP3ExampleViewController() }
      ),
      DemoItem(
        title: "HLS on demand",
        subtitle: "Adaptive streaming in audio-only presentation mode.",
        factory: { FKAudioPlayerHLSExampleViewController() }
      ),
      DemoItem(
        title: "UIView embed helper",
        subtitle: "`fk_embedAudioPlayer` constraints helper.",
        factory: { FKAudioPlayerEmbedHelperExampleViewController() }
      ),
      DemoItem(
        title: "Compact style",
        subtitle: "`FKAudioPlayerViewStyle.compact` layout.",
        factory: { FKAudioPlayerCompactStyleExampleViewController() }
      ),
    ]),
    DemoSection(title: "Queue", items: [
      DemoItem(
        title: "Sequential queue",
        subtitle: "`loadQueue`, next/previous, natural end-of-queue stop.",
        factory: { FKAudioPlayerSequentialQueueExampleViewController() }
      ),
      DemoItem(
        title: "Shuffle",
        subtitle: "`FKAudioQueueMode.shuffle` random order.",
        factory: { FKAudioPlayerShuffleExampleViewController() }
      ),
      DemoItem(
        title: "Repeat modes",
        subtitle: "Repeat one, repeat all, and coordinator playlist navigation.",
        factory: { FKAudioPlayerRepeatModesExampleViewController() }
      ),
      DemoItem(
        title: "Queue editing",
        subtitle: "`insertNext`, `append`, and `remove(at:)`.",
        factory: { FKAudioPlayerQueueEditingExampleViewController() }
      ),
    ]),
    DemoSection(title: "Lyrics & podcast", items: [
      DemoItem(
        title: "Bundled LRC",
        subtitle: "Loads `sample.lrc` from the example bundle.",
        factory: { FKAudioPlayerLRCLyricsExampleViewController() }
      ),
      DemoItem(
        title: "Plain lyrics text",
        subtitle: "Inline `lyricsText` with timestamp parsing.",
        factory: { FKAudioPlayerPlainLyricsExampleViewController() }
      ),
      DemoItem(
        title: "Podcast chapters",
        subtitle: "`FKAudioChapter` markers and `seekToChapter`.",
        factory: { FKAudioPlayerChaptersExampleViewController() }
      ),
    ]),
    DemoSection(title: "UI & chrome", items: [
      DemoItem(
        title: "Mini bar",
        subtitle: "`FKAudioMiniBar` docked above the safe area.",
        factory: { FKAudioPlayerMiniBarExampleViewController() }
      ),
      DemoItem(
        title: "Now Playing page",
        subtitle: "`FKAudioPlayerViewController` full-screen host.",
        factory: { FKAudioPlayerNowPlayingExampleViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "`FKAudioPlayerSwiftUIView` in UIHostingController.",
        factory: { FKAudioPlayerSwiftUIExampleViewController() }
      ),
      DemoItem(
        title: "Waveform",
        subtitle: "Static peak waveform from a downloaded copy of the track URL (independent of AVPlayer).",
        factory: { FKAudioPlayerWaveformExampleViewController() }
      ),
    ]),
    DemoSection(title: "Tools", items: [
      DemoItem(
        title: "Sleep timer",
        subtitle: "`setSleepTimer` pause/stop actions.",
        factory: { FKAudioPlayerSleepTimerExampleViewController() }
      ),
      DemoItem(
        title: "Stop after current",
        subtitle: "`setStopAfterCurrentItem` on queue completion.",
        factory: { FKAudioPlayerStopAfterCurrentExampleViewController() }
      ),
      DemoItem(
        title: "Playground",
        subtitle: "Cross-track fade, playback rate, and per-item rate memory.",
        factory: { FKAudioPlayerPlaygroundExampleViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Lock screen Now Playing",
        subtitle: "Lock device to see system transport on the lock screen.",
        factory: { FKAudioPlayerLockScreenExampleViewController() }
      ),
      DemoItem(
        title: "Delegate event log",
        subtitle: "All `FKAudioPlayerDelegate` callbacks.",
        factory: { FKAudioPlayerDelegateLogExampleViewController() }
      ),
      DemoItem(
        title: "Play history",
        subtitle: "`FKAudioPlayHistoryStore` recent item IDs.",
        factory: { FKAudioPlayerHistoryExampleViewController() }
      ),
      DemoItem(
        title: "QoE snapshot",
        subtitle: "`FKAudioQoEReporter` analytics plugin.",
        factory: { FKAudioPlayerQoEExampleViewController() }
      ),
      DemoItem(
        title: "Watch / Widget snapshot",
        subtitle: "`FKAudioPlaybackSnapshot` from the player facade.",
        factory: { FKAudioPlayerWatchWidgetExampleViewController() }
      ),
      DemoItem(
        title: "CarPlay coordinator",
        subtitle: "Registers next/previous remote commands; `refreshMetadata()` only toggles Now Playing.",
        factory: { FKAudioPlayerCarPlayExampleViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKAudioPlayer"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].items[indexPath.row].factory(), animated: true)
  }
}
