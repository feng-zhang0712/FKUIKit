import FKUIKit
import UIKit

/// Three bouncing dots — demonstrates ``FKRefreshContentView`` without the default arrow/spinner.
final class FKDotsRefreshContentView: UIView, FKRefreshContentView {

  private let dots: [UIView] = (0..<3).map { _ in
    let v = UIView()
    v.layer.cornerRadius = 5
    return v
  }

  private let label = UILabel()
  private var isAnimating = false
  private var dotColor: UIColor = .systemBlue

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    dots.forEach {
      $0.backgroundColor = dotColor
      addSubview($0)
    }

    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.alpha = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)

    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let size: CGFloat = 10
    let spacing: CGFloat = 8
    let totalW = CGFloat(dots.count) * size + CGFloat(dots.count - 1) * spacing
    var x = bounds.midX - totalW / 2
    let y = bounds.midY - size / 2 - 8
    for dot in dots {
      dot.frame = CGRect(x: x, y: y, width: size, height: size)
      x += size + spacing
    }
  }

  func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState) {
    applyTint(control.configuration.tintColor)

    switch state {
    case .idle:
      stopBouncing()
      setLabel(nil)
      setDotsAlpha(0)
    case .pulling:
      stopBouncing()
      setLabel(nil)
    case .readyToRefresh, .triggered:
      setDotsAlpha(1)
      setLabel(nil)
    case .refreshing, .loadingMore:
      setDotsAlpha(1)
      startBouncing()
      setLabel(nil)
    case .finished:
      stopBouncing()
      setLabel(control.kind == .loadMore ? "Loaded" : "Done")
    case .listEmpty:
      stopBouncing()
      setDotsAlpha(0)
      setLabel("No content")
    case .noMoreData:
      stopBouncing()
      setDotsAlpha(0)
      setLabel("No more data")
    case .failed:
      stopBouncing()
      setLabel("Failed")
    }
  }

  func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat) {
    setDotsAlpha(progress)
    for (i, dot) in dots.enumerated() {
      let scale = 0.5 + 0.5 * min(1, max(0, progress - CGFloat(i) * 0.15))
      dot.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
  }

  private func startBouncing() {
    guard !isAnimating else { return }
    isAnimating = true
    for (i, dot) in dots.enumerated() {
      animateDot(dot, delay: Double(i) * 0.15)
    }
  }

  private func animateDot(_ dot: UIView, delay: Double) {
    UIView.animate(
      withDuration: 0.4,
      delay: delay,
      options: [.repeat, .autoreverse, .allowUserInteraction],
      animations: { dot.transform = CGAffineTransform(translationX: 0, y: -8) }
    )
  }

  private func stopBouncing() {
    guard isAnimating else { return }
    isAnimating = false
    dots.forEach {
      $0.layer.removeAllAnimations()
      $0.transform = .identity
    }
  }

  private func setDotsAlpha(_ alpha: CGFloat) {
    dots.forEach { $0.alpha = alpha }
  }

  private func setLabel(_ text: String?) {
    label.text = text
    UIView.animate(withDuration: 0.2) {
      self.label.alpha = text == nil ? 0 : 1
    }
  }

  private func applyTint(_ color: UIColor) {
    guard color != dotColor else { return }
    dotColor = color
    dots.forEach { $0.backgroundColor = color }
    label.textColor = color
  }
}
