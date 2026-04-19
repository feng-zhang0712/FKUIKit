//
// FKRefreshDemoCommon.swift
// FKKitExamples — FKRefresh demos
//
// Shared state formatting, fake network delay, demo animated image, and `FKDotsRefreshContentView`.
//

import FKUIKit
import UIKit

enum FKRefreshDemoCommon {

  /// Human-readable state for the status strip (examples only).
  static func stateDescription(_ state: FKRefreshState) -> String {
    switch state {
    case .idle: return "idle"
    case .pulling(let p): return String(format: "pulling(%.2f)", p)
    case .triggered: return "triggered"
    case .refreshing: return "refreshing"
    case .finished: return "finished"
    case .listEmpty: return "listEmpty"
    case .noMoreData: return "noMoreData"
    case .failed: return "failed"
    }
  }

  /// Two-frame animated image for ``FKGIFRefreshContentView`` (no asset file required).
  static func makeDemoAnimatedImage() -> UIImage {
    let size = CGSize(width: 36, height: 36)
    let colors: [UIColor] = [.systemOrange, .systemTeal]
    let frames: [UIImage] = colors.map { color in
      let r = UIGraphicsImageRenderer(size: size)
      return r.image { ctx in
        color.setFill()
        ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
      }
    }
    return UIImage.animatedImage(with: frames, duration: 0.35) ?? frames[0]
  }

  /// Simulates async work; always invokes `completion` on the main queue.
  static func simulateRequest(delay: TimeInterval, _ completion: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: completion)
  }
}

// MARK: - Dots indicator (custom FKRefreshContentView)

/// Three bouncing dots — demonstrates implementing ``FKRefreshContentView`` without the default arrow.
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
    case .triggered:
      setDotsAlpha(1)
      setLabel(nil)
    case .refreshing:
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
