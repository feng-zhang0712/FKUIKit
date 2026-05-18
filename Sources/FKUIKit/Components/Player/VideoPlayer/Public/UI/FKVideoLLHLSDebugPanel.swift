import UIKit

/// Debug overlay for LL-HLS latency and buffer metrics (Phase 3).
@MainActor
public final class FKVideoLLHLSDebugPanel: UIView {

  private let label = UILabel()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.black.withAlphaComponent(0.55)
    layer.cornerRadius = 8
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .white
    label.numberOfLines = 0
    addSubview(label)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds.insetBy(dx: 8, dy: 6)
  }

  public func update(player: FKVideoPlayer) {
    let latency = player.liveLatencySeconds.map { String(format: "%.1fs", $0) } ?? "—"
    let bufferEnd = player.bufferedTimeRanges.map(\.upperBound).max() ?? 0
    let state = "\(player.state)"
    label.text = "LL-HLS Debug\nlatency: \(latency)\nbuffer: \(String(format: "%.1f", bufferEnd))s\nstate: \(state)"
  }
}
