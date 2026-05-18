import FKUIKit
import UIKit

/// Vertical feed with visibility-based autoplay and a player pool.
@MainActor
final class FKVideoPlayerFeedExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  private let samples = [
    FKVideoPlayerExampleCatalog.progressiveItem(title: "Feed clip 1"),
    FKVideoPlayerExampleCatalog.hlsVODItem(title: "Feed clip 2"),
    FKVideoPlayerExampleCatalog.progressiveItem(title: "Feed clip 3"),
  ]

  private let pool = FKVideoPlayerPool(maxPlayers: 2)
  private lazy var feedCoordinator = FKVideoFeedPlaybackCoordinator(pool: pool)
  private let tableView = UITableView(frame: .zero, style: .plain)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Feed autoplay"
    view.backgroundColor = .systemBackground

    tableView.dataSource = self
    tableView.delegate = self
    tableView.rowHeight = 260
    tableView.separatorStyle = .none
    feedCoordinator.scrollView = tableView
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    samples.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "feed") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "feed")
    cell.selectionStyle = .none
    cell.textLabel?.text = samples[indexPath.row].title

    let tag = 9001
    let surface: UIView
    if let existing = cell.contentView.viewWithTag(tag) {
      surface = existing
    } else {
      surface = UIView()
      surface.tag = tag
      surface.backgroundColor = .black
      surface.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(surface)
      NSLayoutConstraint.activate([
        surface.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 36),
        surface.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
        surface.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
        surface.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
      ])
    }

    surface.subviews.forEach { $0.removeFromSuperview() }
    let player = pool.player(for: cell)
    let playerView = FKVideoPlayerView(frame: surface.bounds)
    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    surface.addSubview(playerView)
    player.bind(to: playerView)
    player.load(samples[indexPath.row])
    feedCoordinator.register(playerView)

    return cell
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    feedCoordinator.scrollViewDidScroll(scrollView)
  }
}
