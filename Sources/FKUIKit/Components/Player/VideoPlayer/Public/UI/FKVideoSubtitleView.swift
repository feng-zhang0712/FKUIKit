import UIKit

/// Renders external subtitle cues over the video.
@MainActor
public final class FKVideoSubtitleView: UIView {

  private let label = UILabel()

  public var style: FKVideoSubtitleStyle = .default {
    didSet { applyStyle() }
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    label.numberOfLines = 0
    label.textAlignment = .center
    addSubview(label)
    applyStyle()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let inset = style.bottomInset
    label.frame = CGRect(
      x: 16,
      y: bounds.height - inset - 60,
      width: bounds.width - 32,
      height: 60
    )
  }

  public func show(text: String?) {
    label.text = text
    isHidden = text?.isEmpty != false
  }

  private func applyStyle() {
    label.font = .systemFont(ofSize: style.fontSize, weight: .medium)
    label.textColor = style.textColor()
    label.backgroundColor = style.backgroundColor()
    label.layer.cornerRadius = 4
    label.layer.masksToBounds = true
    setNeedsLayout()
  }
}
