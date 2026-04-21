//
//  FKButtonExampleViewController+InteractionExamples.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

extension FKButtonExampleBaseViewController {

  func makeThrottleExamples() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "Throttles touchUpInside / primaryActionTriggered. Default interval is 1s; the right button uses 0.35s."
    )

    let status = UILabel()
    status.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    status.textColor = .secondaryLabel
    status.textAlignment = .center
    status.numberOfLines = 0
    status.text = "Delivered taps: 0 (1s throttle) · 0 (0.35s throttle)"

    var left = 0
    var right = 0

    func style(_ b: FKButton, title: String) {
      b.content = .init(kind: .textOnly)
      b.setTitles(
        normal: .init(text: title, font: .systemFont(ofSize: 14, weight: .semibold), color: .white)
      )
      b.setAppearances(
        .init(
          normal: .filled(backgroundColor: .systemIndigo, cornerStyle: .init(corner: .fixed(10)))
        )
      )
    }

    let slow = FKButton()
    style(slow, title: "Throttle 1s (default)")
    slow.minimumTapInterval = 1
    slow.heightAnchor.constraint(equalToConstant: 44).isActive = true
    slow.widthAnchor.constraint(equalToConstant: 220).isActive = true
    slow.addAction(UIAction { [weak self] _ in
      left += 1
      status.text = "Delivered taps: \(left) (1s throttle) · \(right) (0.35s throttle)"
      self?.recordDemoTap("Throttle · 1s delivered")
    }, for: .touchUpInside)

    let fast = FKButton()
    style(fast, title: "Throttle 0.35s")
    fast.minimumTapInterval = 0.35
    fast.heightAnchor.constraint(equalToConstant: 44).isActive = true
    fast.widthAnchor.constraint(equalToConstant: 220).isActive = true
    fast.addAction(UIAction { [weak self] _ in
      right += 1
      status.text = "Delivered taps: \(left) (1s throttle) · \(right) (0.35s throttle)"
      self?.recordDemoTap("Throttle · 0.35s delivered")
    }, for: .touchUpInside)

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(fullWidthLayoutWrapping(status))
    outer.addArrangedSubview(horizontallyCentered(slow))
    outer.addArrangedSubview(horizontallyCentered(fast))
    return outer
  }

  func makeHitTestExpansionExample() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 12
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "Visual size is 28×28pt; hitTestEdgeInsets expand the tappable rect without changing layout."
    )

    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 24
    row.distribution = .equalSpacing

    let tiny = FKButton()
    tiny.content = .init(kind: .textOnly)
    tiny.setTitles(
      normal: .init(text: "·", font: .systemFont(ofSize: 16, weight: .bold), color: .white)
    )
    tiny.setAppearances(
      .init(normal: .filled(backgroundColor: .systemRed, cornerStyle: .init(corner: .fixed(6))))
    )
    tiny.hitTestEdgeInsets = UIEdgeInsets(top: -24, left: -24, bottom: -24, right: -24)
    tiny.widthAnchor.constraint(equalToConstant: 28).isActive = true
    tiny.heightAnchor.constraint(equalToConstant: 28).isActive = true
    tiny.addAction(UIAction { [weak self] _ in
      self?.recordDemoTap("Hit test · tiny visual")
    }, for: .touchUpInside)

    let outline = UIView()
    outline.translatesAutoresizingMaskIntoConstraints = false
    outline.layer.borderColor = UIColor.systemOrange.cgColor
    outline.layer.borderWidth = 1
    outline.layer.cornerRadius = 6
    outline.widthAnchor.constraint(equalToConstant: 76).isActive = true
    outline.heightAnchor.constraint(equalToConstant: 76).isActive = true
    outline.addSubview(tiny)
    NSLayoutConstraint.activate([
      tiny.centerXAnchor.constraint(equalTo: outline.centerXAnchor),
      tiny.centerYAnchor.constraint(equalTo: outline.centerYAnchor),
    ])

    let hint = UILabel()
    hint.font = .preferredFont(forTextStyle: .caption1)
    hint.textColor = .secondaryLabel
    hint.textAlignment = .center
    hint.numberOfLines = 0
    hint.text = "Orange box ≈ expanded hit slop. Tap inside the box but outside the red square."

    row.addArrangedSubview(outline)

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(horizontallyCentered(row))
    outer.addArrangedSubview(fullWidthLayoutWrapping(hint))
    return outer
  }

  func makeLongPressExamples() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "Long-press: began + repeating ticks (Timer) + ended. `longPressMinimumDuration` = 0.45s, `longPressRepeatTickInterval` = 0.12s."
    )

    let status = UILabel()
    status.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    status.textColor = .secondaryLabel
    status.textAlignment = .center
    status.numberOfLines = 0
    status.text = "Hold the button…"

    let b = FKButton()
    b.content = .init(kind: .textOnly)
    b.setTitles(
      normal: .init(text: "Hold me", font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
    )
    b.setAppearances(
      .init(
        normal: .filled(backgroundColor: .systemTeal, cornerStyle: .init(corner: .fixed(12)))
      )
    )
    b.longPressMinimumDuration = 0.45
    b.longPressRepeatTickInterval = 0.12
    var ticks = 0
    b.onLongPressBegan = {
      ticks = 0
      status.text = "Began — repeating…"
    }
    b.onLongPressRepeatTick = {
      ticks += 1
      status.text = "Repeating tick #\(ticks)"
    }
    b.onLongPressEnded = { [weak self] in
      status.text = "Ended after \(ticks) tick(s)"
      self?.recordDemoTap("Long press ended")
    }
    b.heightAnchor.constraint(equalToConstant: 48).isActive = true
    b.widthAnchor.constraint(equalToConstant: 200).isActive = true

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(fullWidthLayoutWrapping(status))
    outer.addArrangedSubview(horizontallyCentered(b))
    return outer
  }

  func makeGradientAndHighlightControlExample() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "Linear gradient background, shadow, border. Selected toggles palette. Second row disables highlight feedback (no dim / scale)."
    )

    let g = FKButton.LinearGradient(
      colors: [.systemPurple, .systemBlue],
      startPoint: CGPoint(x: 0, y: 0.5),
      endPoint: CGPoint(x: 1, y: 0.5)
    )

    let normalA = FKButton.Appearance(
      cornerStyle: .init(corner: .fixed(14)),
      border: .init(width: 1, color: UIColor.white.withAlphaComponent(0.35)),
      backgroundColor: .clear,
      backgroundGradient: g,
      shadow: .init(color: .systemPurple, opacity: 0.25, offset: CGSize(width: 0, height: 4), radius: 8),
      contentInsets: .init(top: 10, leading: 18, bottom: 10, trailing: 18)
    )

    let selectedA = FKButton.Appearance(
      cornerStyle: .init(corner: .fixed(14)),
      border: .init(width: 1, color: UIColor.white.withAlphaComponent(0.55)),
      backgroundColor: .clear,
      backgroundGradient: .init(colors: [.systemOrange, .systemPink]),
      shadow: .init(color: .systemOrange, opacity: 0.22, offset: CGSize(width: 0, height: 4), radius: 8),
      contentInsets: .init(top: 10, leading: 18, bottom: 10, trailing: 18)
    )

    let gradientBtn = FKButton()
    gradientBtn.content = .init(kind: .textOnly)
    gradientBtn.setTitles(
      normal: .init(text: "Gradient · Normal", font: .systemFont(ofSize: 15, weight: .semibold), color: .white),
      selected: .init(text: "Gradient · Selected", font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
    )
    gradientBtn.setAppearance(normalA, for: .normal)
    gradientBtn.setAppearance(selectedA, for: .selected)
    gradientBtn.setAppearance(selectedA, for: .highlighted)
    gradientBtn.setAppearance(
      normalA.merged(with: .init(alpha: 0.55, interaction: .init(pressedAlpha: 1, pressedScale: 1, hitTestOutsets: .zero))),
      for: .disabled
    )
    gradientBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
    gradientBtn.widthAnchor.constraint(equalToConstant: 260).isActive = true
    gradientBtn.addAction(UIAction { [weak gradientBtn] _ in
      gradientBtn?.isSelected.toggle()
    }, for: .touchUpInside)

    let flat = FKButton()
    flat.content = .init(kind: .textOnly)
    flat.setTitles(
      normal: .init(text: "No highlight feedback", font: .systemFont(ofSize: 14, weight: .semibold), color: .label)
    )
    let noFeedback = FKButton.Interaction(
      pressedAlpha: 1,
      pressedScale: 1,
      hitTestOutsets: .init(top: 8, left: 8, bottom: 8, right: 8),
      isHighlightFeedbackEnabled: false
    )
    flat.setAppearances(
      .init(
        normal: FKButton.Appearance(
          cornerStyle: .init(corner: .fixed(12)),
          border: .init(width: 1, color: .separator),
          backgroundColor: .tertiarySystemBackground,
          interaction: noFeedback
        )
      )
    )
    flat.heightAnchor.constraint(equalToConstant: 44).isActive = true
    flat.widthAnchor.constraint(equalToConstant: 260).isActive = true
    flat.addAction(UIAction { [weak self] _ in
      self?.recordDemoTap("No highlight feedback")
    }, for: .touchUpInside)

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(horizontallyCentered(gradientBtn))
    outer.addArrangedSubview(horizontallyCentered(flat))
    return outer
  }

  func makeDisabledDimmingExample() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "When disabled, `automaticallyDimsWhenDisabled` applies `disabledDimmingAlpha` on top of resolved appearance alpha."
    )

    let dimmed = FKButton()
    dimmed.content = .init(kind: .textOnly)
    dimmed.setTitles(normal: .init(text: "Dimmed (default)", font: .systemFont(ofSize: 14, weight: .semibold), color: .label))
    dimmed.setAppearances(.init(normal: .filled(backgroundColor: .systemGray5, cornerStyle: .init(corner: .fixed(10)))))
    dimmed.isEnabled = false
    dimmed.automaticallyDimsWhenDisabled = true
    dimmed.disabledDimmingAlpha = 0.5

    let raw = FKButton()
    raw.content = .init(kind: .textOnly)
    raw.setTitles(normal: .init(text: "Not dimmed", font: .systemFont(ofSize: 14, weight: .semibold), color: .label))
    raw.setAppearances(.init(normal: .filled(backgroundColor: .systemGray5, cornerStyle: .init(corner: .fixed(10)))))
    raw.isEnabled = false
    raw.automaticallyDimsWhenDisabled = false

    for b in [dimmed, raw] {
      b.heightAnchor.constraint(equalToConstant: 44).isActive = true
      b.widthAnchor.constraint(equalToConstant: 220).isActive = true
    }

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(horizontallyCentered(dimmed))
    outer.addArrangedSubview(horizontallyCentered(raw))
    return outer
  }

  func makeLoadingExamples() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 12
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "Two styles: `.overlay` (dimmed content under spinner) and `.replacesContent` (hides stack, optional status text beside spinner). `performWhileLoading` restores the previous presentation."
    )

    let overlayBtn = FKButton()
    overlayBtn.content = .init(kind: .textAndImage(.leading))
    overlayBtn.setTitles(
      normal: .init(text: "Overlay style", font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
    )
    overlayBtn.setLeadingImages(
      normal: .init(systemName: "arrow.down.circle.fill", tintColor: .white, spacingToTitle: 10)
    )
    overlayBtn.setAppearances(
      .init(normal: .filled(backgroundColor: .systemBlue, cornerStyle: .init(corner: .fixed(12))))
    )
    overlayBtn.loadingPresentationStyle = .overlay(dimmedContentAlpha: 0.35)
    overlayBtn.loadingActivityIndicatorColor = .white
    overlayBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
    overlayBtn.widthAnchor.constraint(equalToConstant: 260).isActive = true
    overlayBtn.addAction(UIAction { [weak overlayBtn] _ in
      guard let overlayBtn else { return }
      Task { @MainActor in
        await overlayBtn.performWhileLoading(presentation: .overlay(dimmedContentAlpha: 0.3)) {
          try? await Task.sleep(nanoseconds: 1_200_000_000)
        }
      }
    }, for: .touchUpInside)

    let replaceBtn = FKButton()
    replaceBtn.content = .init(kind: .textAndImage(.leading))
    replaceBtn.setTitles(
      normal: .init(text: "Hide + status text", font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
    )
    replaceBtn.setLeadingImages(
      normal: .init(systemName: "icloud.and.arrow.down", tintColor: .white, spacingToTitle: 10)
    )
    replaceBtn.setAppearances(
      .init(normal: .filled(backgroundColor: .systemIndigo, cornerStyle: .init(corner: .fixed(12))))
    )
    replaceBtn.loadingActivityIndicatorColor = .white
    replaceBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
    replaceBtn.widthAnchor.constraint(equalToConstant: 260).isActive = true
    replaceBtn.addAction(UIAction { [weak replaceBtn] _ in
      guard let replaceBtn else { return }
      Task { @MainActor in
        let msg = FKButton.ReplacedContentLoadingOptions(
          spacingAfterIndicator: 10,
          message: "处理中…",
          messageFont: .systemFont(ofSize: 14, weight: .medium),
          messageColor: .white
        )
        await replaceBtn.performWhileLoading(presentation: .replacesContent(msg)) {
          try? await Task.sleep(nanoseconds: 1_400_000_000)
        }
      }
    }, for: .touchUpInside)

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(horizontallyCentered(overlayBtn))
    outer.addArrangedSubview(horizontallyCentered(replaceBtn))
    return outer
  }

  func makeImageTitleSpacingExample() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "`FKButton.ImageAttributes.spacingToTitle` controls the stack spacing between image and title (system UIButton cannot)."
    )

    func row(spacing: CGFloat, label: String) -> FKButton {
      let b = FKButton()
      b.content = .init(kind: .textAndImage(.leading))
      b.setTitles(
        normal: .init(text: label, font: .systemFont(ofSize: 14, weight: .semibold), color: .label)
      )
      b.setLeadingImages(
        normal: .init(
          systemName: "star.fill",
          tintColor: .systemYellow,
          fixedSize: CGSize(width: 22, height: 22),
          spacingToTitle: spacing
        )
      )
      b.setAppearances(
        .init(normal: .init(cornerStyle: .init(corner: .fixed(10)), border: .init(width: 1, color: .separator), backgroundColor: .tertiarySystemBackground))
      )
      b.heightAnchor.constraint(equalToConstant: 44).isActive = true
      b.widthAnchor.constraint(equalToConstant: 260).isActive = true
      b.addAction(UIAction { [weak self] _ in
        self?.recordDemoTap("Spacing \(spacing)")
      }, for: .touchUpInside)
      return b
    }

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(horizontallyCentered(row(spacing: 4, label: "spacingToTitle = 4")))
    outer.addArrangedSubview(horizontallyCentered(row(spacing: 20, label: "spacingToTitle = 20")))
    return outer
  }

  func makeChainingExample() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel("Fluent configuration returning `Self`.")

    let b = FKButton()
      .withContent(.textOnly)
      .withMinimumTapInterval(0.8)
      .withHitTestEdgeInsets(UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
      .withAutomaticallyDimsWhenDisabled(true)
    b.setTitles(normal: .init(text: "Chained setup", font: .systemFont(ofSize: 15, weight: .semibold), color: .white))
    b.setAppearances(.init(normal: .filled(backgroundColor: .systemBrown, cornerStyle: .init(corner: .fixed(11)))))
    b.heightAnchor.constraint(equalToConstant: 46).isActive = true
    b.widthAnchor.constraint(equalToConstant: 220).isActive = true
    b.addAction(UIAction { [weak self] _ in
      self?.recordDemoTap("Chaining")
    }, for: .touchUpInside)

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(horizontallyCentered(b))
    return outer
  }

  func makeGlobalStyleSnapshotExample() -> UIView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let caption = captionLabel(
      "Assign `FKButton.GlobalStyle.defaultAppearances` before creating buttons (e.g. in AppDelegate). This demo snapshots defaults, builds one control, then restores."
    )

    let host = UIStackView()
    host.axis = .vertical
    host.alignment = .center
    host.spacing = 8

    let trigger = UIButton(type: .system)
    trigger.setTitle("Instantiate FKButton() with template GlobalStyle", for: .normal)
    trigger.titleLabel?.numberOfLines = 0
    trigger.titleLabel?.lineBreakMode = .byWordWrapping
    trigger.titleLabel?.textAlignment = .center
    trigger.addAction(UIAction { [weak self] _ in
      let previous = FKButton.GlobalStyle.defaultAppearances
      FKButton.GlobalStyle.defaultAppearances = Self.templateStateAppearancesForGlobalStyleDemo()
      let button = FKButton()
      button.content = .init(kind: .textOnly)
      button.setTitles(
        normal: .init(text: "From GlobalStyle", font: .systemFont(ofSize: 14, weight: .semibold), color: .white)
      )
      FKButton.GlobalStyle.defaultAppearances = previous

      button.heightAnchor.constraint(equalToConstant: 44).isActive = true
      button.widthAnchor.constraint(equalToConstant: 220).isActive = true
      button.addAction(UIAction { [weak self] _ in
        self?.recordDemoTap("GlobalStyle snapshot button")
      }, for: .touchUpInside)

      host.arrangedSubviews.forEach { v in
        if v is FKButton { v.removeFromSuperview() }
      }
      host.addArrangedSubview(button)
      self?.recordDemoTap("GlobalStyle snapshot · created")
    }, for: .touchUpInside)

    outer.addArrangedSubview(caption)
    outer.addArrangedSubview(fullWidthLayoutWrapping(trigger))
    outer.addArrangedSubview(horizontallyCentered(host))
    return outer
  }

  func makeStoryboardAttributesHint() -> UIView {
    captionLabel(
      "Storyboard / XIB: set class to `FKButton`, then use the FK-prefixed inspectables (`fk_minimumTapInterval`, `fk_hitTestMargin`, …). The control is `@IBDesignable` for canvas preview."
    )
  }

  private static func templateStateAppearancesForGlobalStyleDemo() -> FKButton.StateAppearances {
    let normal = FKButton.Appearance(
      cornerStyle: .init(corner: .capsule),
      border: .init(width: 0, color: .clear),
      backgroundColor: .systemGreen
    )
    let selected = FKButton.Appearance(
      cornerStyle: .init(corner: .capsule),
      border: .init(width: 0, color: .clear),
      backgroundColor: .systemMint
    )
    return .init(
      normal: normal,
      selected: selected,
      highlighted: selected,
      disabled: normal.merged(with: .init(alpha: 0.45))
    )
  }

  private func captionLabel(_ text: String) -> UIView {
    let l = UILabel()
    l.text = text
    l.font = .preferredFont(forTextStyle: .caption1)
    l.textColor = .secondaryLabel
    l.textAlignment = .center
    l.numberOfLines = 0
    l.lineBreakMode = .byWordWrapping
    return fullWidthLayoutWrapping(l)
  }
}
