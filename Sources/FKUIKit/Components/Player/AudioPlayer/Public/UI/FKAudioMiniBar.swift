import UIKit

enum FKAudioMiniBarChromeMetrics {
  static let barHeight: CGFloat = 52
  static let artworkSize: CGFloat = 34
  static let playButtonSize: CGFloat = 36
  static let itemSpacing: CGFloat = 12
  static let leadingInset: CGFloat = 20
  static let trailingInset: CGFloat = 20

  static func textWidth(for barWidth: CGFloat) -> CGFloat {
    let reserved = leadingInset + artworkSize + itemSpacing + itemSpacing + playButtonSize + trailingInset
    return max(72, barWidth - reserved)
  }
}

/// Compact bottom mini player bar for tab-based apps.
@MainActor
public final class FKAudioMiniBar: UIView {

  private let contentView = FKAudioPlayerView(style: .miniBar)
  private weak var player: FKAudioPlayer?
  private lazy var openNowPlayingTap: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer(target: self, action: #selector(openNowPlaying))
    tap.delegate = self
    return tap
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    clipsToBounds = false
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.14
    layer.shadowRadius = 12
    layer.shadowOffset = CGSize(width: 0, height: 4)
    installContentViewIfNeeded()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let radius = bounds.height / 2
    contentView.layer.cornerRadius = radius
  }

  private func installContentViewIfNeeded() {
    guard contentView.superview == nil else { return }
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.clipsToBounds = true
    contentView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentView)
    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    addGestureRecognizer(openNowPlayingTap)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: FKAudioMiniBarChromeMetrics.barHeight)
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    installContentViewIfNeeded()
  }

  public func bind(player: FKAudioPlayer) {
    installContentViewIfNeeded()
    self.player = player
    contentView.bind(player: player)
  }

  /// Refreshes transport state from the bound player (call after late binding or modal dismiss).
  public func syncFromPlayer() {
    guard let player else { return }
    if let item = player.currentItem {
      reload(for: item)
    }
    handleStateChange(player.state)
    updateProgress(current: player.currentTime, duration: player.duration)
  }

  public func reload(for item: FKAudioItem) {
    contentView.reload(for: item)
  }

  public func handleStateChange(_ state: FKMediaPlaybackState) {
    contentView.handleStateChange(state)
  }

  public func updateProgress(current: TimeInterval, duration: TimeInterval) {
    contentView.updateProgress(current: current, duration: duration, buffered: [])
  }

  public func reset() {
    contentView.reset()
  }

  @objc
  private func openNowPlaying() {
    guard let player, let host = nearestViewController() else { return }
    let controller = FKAudioPlayerViewController(player: player)
    host.present(controller, animated: true)
  }

  private func nearestViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }
}

extension FKAudioMiniBar: UIGestureRecognizerDelegate {

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    var view: UIView? = touch.view
    while let current = view {
      if current is UIButton {
        return false
      }
      view = current.superview
    }
    return true
  }
}
