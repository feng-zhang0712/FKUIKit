import UIKit

/// Shows a thumbnail preview while scrubbing (Phase 4).
@MainActor
public final class FKVideoThumbnailSeekPreview: UIView {

  private let imageView = UIImageView()
  private let timeLabel = UILabel()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    isHidden = true
    backgroundColor = UIColor.black.withAlphaComponent(0.75)
    layer.cornerRadius = 8
    clipsToBounds = true

    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    addSubview(imageView)

    timeLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    timeLabel.textColor = .white
    timeLabel.textAlignment = .center
    addSubview(timeLabel)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    imageView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 20)
    timeLabel.frame = CGRect(x: 0, y: bounds.height - 20, width: bounds.width, height: 20)
  }

  public func show(image: UIImage?, time: TimeInterval, centerX: CGFloat, in host: UIView) {
    let size = CGSize(width: 140, height: 90)
    frame = CGRect(
      x: min(max(8, centerX - size.width / 2), host.bounds.width - size.width - 8),
      y: host.bounds.height * 0.35,
      width: size.width,
      height: size.height
    )
    imageView.image = image
    timeLabel.text = formatTime(time)
    isHidden = false
    if superview !== host {
      host.addSubview(self)
    }
    host.bringSubviewToFront(self)
  }

  public func hide() {
    isHidden = true
  }

  private func formatTime(_ time: TimeInterval) -> String {
    let total = max(0, Int(time))
    return String(format: "%02d:%02d", total / 60, total % 60)
  }
}
