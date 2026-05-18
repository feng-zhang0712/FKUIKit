import UIKit

/// Displays live status and estimated latency.
@MainActor
public final class FKVideoLiveBadgeView: UIView {

  private let label = UILabel()
  private let goLiveButton = UIButton(type: .system)

  public var onGoLiveTapped: (() -> Void)?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
    layer.cornerRadius = 4
    clipsToBounds = true

    label.font = .systemFont(ofSize: 12, weight: .bold)
    label.textColor = .white
    label.text = "LIVE"
    addSubview(label)

    goLiveButton.setTitle("Go Live", for: .normal)
    goLiveButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
    goLiveButton.addTarget(self, action: #selector(goLive), for: .touchUpInside)
    addSubview(goLiveButton)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    label.sizeToFit()
    label.frame.origin = CGPoint(x: 8, y: (bounds.height - label.bounds.height) / 2)
    goLiveButton.sizeToFit()
    goLiveButton.frame = CGRect(
      x: label.frame.maxX + 8,
      y: 0,
      width: goLiveButton.bounds.width + 8,
      height: bounds.height
    )
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: 120, height: 28)
  }

  public func update(isLive: Bool, latencySeconds: TimeInterval?) {
    isHidden = !isLive
    if let latencySeconds, latencySeconds > 1 {
      label.text = String(format: "LIVE · ~%.0fs", latencySeconds)
    } else {
      label.text = "LIVE"
    }
    setNeedsLayout()
  }

  @objc
  private func goLive() {
    onGoLiveTapped?()
  }
}
