import FKUIKit
import UIKit

/// Lists ``FKVideoPlayer`` example screens grouped by feature area.
final class FKVideoPlayerExamplesHubViewController: UITableViewController {

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
        title: "Progressive MP4",
        subtitle: "HTTPS file, default controls, poster image.",
        factory: { FKVideoPlayerProgressiveExampleViewController() }
      ),
      DemoItem(
        title: "HLS on demand",
        subtitle: "Adaptive streaming with multi-bitrate selection.",
        factory: { FKVideoPlayerHLSVODExampleViewController() }
      ),
      DemoItem(
        title: "UIView embed helper",
        subtitle: "`fk_embedVideoPlayer` constraints helper.",
        factory: { FKVideoPlayerEmbedHelperExampleViewController() }
      ),
    ]),
    DemoSection(title: "Playback", items: [
      DemoItem(
        title: "Playlist & chapters",
        subtitle: "Sequential items, skip intro/outro, chapter seek.",
        factory: { FKVideoPlayerPlaylistExampleViewController() }
      ),
      DemoItem(
        title: "Playground",
        subtitle: "Rate, mute, LL-HLS toggle, peak bitrate, thumbnail scrub.",
        factory: { FKVideoPlayerPlaygroundExampleViewController() }
      ),
    ]),
    DemoSection(title: "Live", items: [
      DemoItem(
        title: "Live HLS",
        subtitle: "Live badge, go-live, optional LL-HLS debug overlay.",
        factory: { FKVideoPlayerLiveExampleViewController() }
      ),
    ]),
    DemoSection(title: "Subtitles & tracks", items: [
      DemoItem(
        title: "External WebVTT",
        subtitle: "Bundled `.vtt` plus embedded track names.",
        factory: { FKVideoPlayerSubtitlesExampleViewController() }
      ),
    ]),
    DemoSection(title: "UI & chrome", items: [
      DemoItem(
        title: "Fullscreen host",
        subtitle: "`FKVideoPlayerViewController` presentation.",
        factory: { FKVideoPlayerFullscreenExampleViewController() }
      ),
      DemoItem(
        title: "Custom control surface",
        subtitle: "Replace `FKDefaultVideoControlView`.",
        factory: { FKVideoPlayerCustomControlsExampleViewController() }
      ),
      DemoItem(
        title: "Mini player",
        subtitle: "Floating `FKVideoMiniPlayerView` shell.",
        factory: { FKVideoPlayerMiniPlayerExampleViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "`FKVideoPlayerSwiftUIView` in UIHostingController.",
        factory: { FKVideoPlayerSwiftUIExampleViewController() }
      ),
    ]),
    DemoSection(title: "Feed & performance", items: [
      DemoItem(
        title: "Feed autoplay",
        subtitle: "`FKVideoFeedPlaybackCoordinator` + `FKVideoPlayerPool`.",
        factory: { FKVideoPlayerFeedExampleViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Extended engine (Core)",
        subtitle: "MKV/DASH are not bundled — format probe table and expected load failures.",
        factory: { FKMediaExtendedEngineExampleViewController() }
      ),
      DemoItem(
        title: "Delegate event log",
        subtitle: "All `FKVideoPlayerDelegate` callbacks.",
        factory: { FKVideoPlayerDelegateLogExampleViewController() }
      ),
      DemoItem(
        title: "Offline HLS download",
        subtitle: "`FKVideoOfflineDownloadManager` registry playback.",
        factory: { FKVideoPlayerOfflineExampleViewController() }
      ),
      DemoItem(
        title: "Pre-roll ads",
        subtitle: "`FKVideoAdPlugin` placeholder interstitial.",
        factory: { FKVideoPlayerAdsExampleViewController() }
      ),
      DemoItem(
        title: "QoE snapshot",
        subtitle: "`FKVideoQoEReporter` analytics plugin.",
        factory: { FKVideoPlayerQoEExampleViewController() }
      ),
      DemoItem(
        title: "SharePlay hook",
        subtitle: "Stub coordinator — `startSharePlay()` throws `notImplemented`.",
        factory: { FKVideoPlayerSharePlayExampleViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKVideoPlayer"
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
