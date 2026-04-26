import UIKit
import FKUIKit

final class FKButtonExampleInteractionViewController: FKButtonExampleBaseViewController {
  override var pageExplanationText: String? {
    "Interaction examples cover primary-action throttling, hit testing, long press callbacks, haptics/sound feedback, and fluent configuration."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleSection(title: "Tap interval (anti double-tap)", content: makeThrottleExamples())
    addExampleSection(title: "Hit test expansion", content: makeHitTestExpansionExample())
    addExampleSection(title: "Long press callbacks", content: makeLongPressExamples())
    addExampleSection(title: "Haptics + sound feedback", content: makeHapticsAndSoundFeedbackExample())
    addExampleSection(title: "Chaining API", content: makeChainingExample())
  }

  private func makeThrottleExamples() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    let status = UILabel()
    status.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    status.textAlignment = .center
    status.text = "Delivered taps: 0 · 0"
    var left = 0
    var right = 0
    func make(_ title: String, interval: TimeInterval, color: UIColor, tap: @escaping () -> Void) -> FKButton {
      let b = FKButton()
      b.content = .init(kind: .textOnly)
      b.setTitle(.init(text: title, font: .systemFont(ofSize: 14, weight: .semibold), color: .white), for: .normal)
      b.setAppearances(.init(normal: .filled(backgroundColor: color, cornerStyle: .init(corner: .fixed(10)))))
      b.minimumTapInterval = interval
      b.heightAnchor.constraint(equalToConstant: 44).isActive = true
      b.widthAnchor.constraint(equalToConstant: 220).isActive = true
      b.addAction(UIAction { _ in tap() }, for: .touchUpInside)
      return b
    }
    let slow = make("Throttle 1.0s", interval: 1, color: .systemIndigo) { [weak self] in
      left += 1
      status.text = "Delivered taps: \(left) · \(right)"
      self?.recordExampleTap("Throttle 1.0s")
    }
    let fast = make("Throttle 0.35s", interval: 0.35, color: .systemBlue) { [weak self] in
      right += 1
      status.text = "Delivered taps: \(left) · \(right)"
      self?.recordExampleTap("Throttle 0.35s")
    }
    stack.addArrangedSubview(captionLabel("Default tap interval is 0. These two buttons override it to 1.0s and 0.35s."))
    stack.addArrangedSubview(fullWidthLayoutWrapping(status))
    stack.addArrangedSubview(horizontallyCentered(slow))
    stack.addArrangedSubview(horizontallyCentered(fast))
    return stack
  }

  private func makeHitTestExpansionExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    let b = FKButton()
    b.content = .init(kind: .textOnly)
    b.setTitle(.init(text: "·", font: .systemFont(ofSize: 16, weight: .bold), color: .white), for: .normal)
    b.setAppearances(.init(normal: .filled(backgroundColor: .systemRed, cornerStyle: .init(corner: .fixed(6)))))
    b.hitTestEdgeInsets = UIEdgeInsets(top: -24, left: -24, bottom: -24, right: -24)
    b.widthAnchor.constraint(equalToConstant: 28).isActive = true
    b.heightAnchor.constraint(equalToConstant: 28).isActive = true
    addTap(b, name: "Hit test expansion")
    stack.addArrangedSubview(captionLabel("Visual size is 28×28pt, but hit area is expanded via hitTestEdgeInsets."))
    stack.addArrangedSubview(horizontallyCentered(b))
    return stack
  }

  private func makeLongPressExamples() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    let status = UILabel()
    status.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    status.textAlignment = .center
    status.text = "Hold the button..."
    let b = FKButton()
    b.content = .init(kind: .textOnly)
    b.setTitle(.init(text: "Hold me", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    b.setAppearances(.init(normal: .filled(backgroundColor: .systemTeal, cornerStyle: .init(corner: .fixed(12)))))
    b.longPressMinimumDuration = 0.45
    b.longPressRepeatTickInterval = 0.12
    var ticks = 0
    b.onLongPressBegan = { ticks = 0; status.text = "Began..." }
    b.onLongPressRepeatTick = { ticks += 1; status.text = "Tick #\(ticks)" }
    b.onLongPressEnded = { [weak self] in self?.recordExampleTap("Long press ended"); status.text = "Ended (\(ticks))" }
    b.heightAnchor.constraint(equalToConstant: 48).isActive = true
    b.widthAnchor.constraint(equalToConstant: 200).isActive = true
    stack.addArrangedSubview(captionLabel("Long press supports began/repeat/ended callbacks."))
    stack.addArrangedSubview(fullWidthLayoutWrapping(status))
    stack.addArrangedSubview(horizontallyCentered(b))
    return stack
  }

  private func makeHapticsAndSoundFeedbackExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let hapticsOnly = FKButton()
    hapticsOnly.content = .init(kind: .textOnly)
    hapticsOnly.setTitle(.init(text: "Haptics only", font: .systemFont(ofSize: 14, weight: .semibold), color: .white), for: .normal)
    hapticsOnly.setAppearances(.init(normal: .filled(backgroundColor: .systemBlue, cornerStyle: .init(corner: .fixed(12)))))
    hapticsOnly.hapticsConfiguration = .init(onPressDown: true, onPrimaryAction: true, impactStyle: .light)
    hapticsOnly.heightAnchor.constraint(equalToConstant: 46).isActive = true
    hapticsOnly.widthAnchor.constraint(equalToConstant: 220).isActive = true
    addTap(hapticsOnly, name: "Feedback haptics")

    let hapticsAndSound = FKButton()
    hapticsAndSound.content = .init(kind: .textOnly)
    hapticsAndSound.setTitle(.init(text: "Haptics + sound", font: .systemFont(ofSize: 14, weight: .semibold), color: .white), for: .normal)
    hapticsAndSound.setAppearances(.init(normal: .filled(backgroundColor: .systemIndigo, cornerStyle: .init(corner: .fixed(12)))))
    hapticsAndSound.hapticsConfiguration = .init(onPressDown: true, onPrimaryAction: true, impactStyle: .medium)
    hapticsAndSound.soundFeedbackConfiguration = .init(onPressDown: false, onPrimaryAction: true, pressDownSound: .system(1104), primaryActionSound: .system(1104))
    hapticsAndSound.heightAnchor.constraint(equalToConstant: 46).isActive = true
    hapticsAndSound.widthAnchor.constraint(equalToConstant: 220).isActive = true
    addTap(hapticsAndSound, name: "Feedback haptics+sound")

    stack.addArrangedSubview(captionLabel("Haptics and sound are optional and independent. Both are disabled by default."))
    stack.addArrangedSubview(horizontallyCentered(hapticsOnly))
    stack.addArrangedSubview(horizontallyCentered(hapticsAndSound))
    return stack
  }

  private func makeChainingExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    let b = FKButton()
      .withContent(.textOnly)
      .withMinimumTapInterval(0.8)
      .withHitTestEdgeInsets(UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
      .withAutomaticallyDimsWhenDisabled(true)
    b.setTitle(.init(text: "Chained setup", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    b.setAppearances(.init(normal: .filled(backgroundColor: .systemBrown, cornerStyle: .init(corner: .fixed(11)))))
    b.heightAnchor.constraint(equalToConstant: 46).isActive = true
    b.widthAnchor.constraint(equalToConstant: 220).isActive = true
    addTap(b, name: "Chaining")
    stack.addArrangedSubview(captionLabel("Fluent API returns Self and can be combined with state-specific setters."))
    stack.addArrangedSubview(horizontallyCentered(b))
    return stack
  }
}
