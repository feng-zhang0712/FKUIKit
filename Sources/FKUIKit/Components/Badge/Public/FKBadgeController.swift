import ObjectiveC
import UIKit

/// Hosts a badge as a **sibling** of the target view (never inserted into the target), with constraints tied to the target's anchors.
@MainActor
public final class FKBadgeController: NSObject {
  public private(set) weak var targetView: UIView?

  public var configuration: FKBadgeConfiguration {
    didSet {
      perform {
        self.applyConfigurationToBadge()
        self.applyResolvedContent(animated: false)
      }
    }
  }

  /// Which anchor of `targetView` the badge aligns to (uses leading/trailing for RTL).
  ///
  /// - Important: Alignment is **center-based**. For corner anchors, the target's corner is aligned to the
  ///   badge view's **center** (not the badge view's corner). Use `offset` to fine-tune placement.
  public var anchor: FKBadgeAnchor {
    didSet {
      perform { self.rebuildLayoutConstraints() }
    }
  }

  /// Extra shift from the anchor point along horizontal and vertical axes.
  public var offset: UIOffset {
    didSet {
      perform { self.rebuildLayoutConstraints() }
    }
  }

  /// Overrides automatic hide/show rules (for example force-hide badges during onboarding).
  public var visibilityPolicy: FKBadgeVisibilityPolicy = .automatic {
    didSet {
      perform { self.applyResolvedContent(animated: false) }
    }
  }

  /// Called when the badge view is tapped. Use `[weak self]` in the closure to avoid retain cycles.
  public var onTap: ((FKBadgeController) -> Void)? {
    didSet {
      perform {
        self.updateTapGestureState()
        self.syncAccessibilityFromResolved()
      }
    }
  }

  /// Optional VoiceOver label. When `nil`, text and numeric badges use the visible string; pure dot badges are not a separate accessibility element until you set a label (or augment the decorated view).
  public var accessibilityBadgeLabel: String? {
    didSet {
      perform { self.syncAccessibilityFromResolved() }
    }
  }

  /// When non-`nil` and `onTap` is set, hit testing uses a square at least this wide and tall, centered on the badge. Typical value: `44`. Default is `nil` (visual bounds only).
  public var minimumTouchTargetSide: CGFloat? {
    didSet {
      perform { self.updateTapGestureState() }
    }
  }

  private let badgeView = FKBadgeContentView()
  private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBadgeTap))
  private var layoutConstraints: [NSLayoutConstraint] = []

  private enum Payload: Equatable {
    case none
    case dot
    case count(Int)
    case text(String)
  }

  private var payload: Payload = .none

  /// - Parameters:
  ///   - target: Decorated view. The badge is attached to `target.superview`, not inside `target`.
  ///   - configuration: Optional initial style. Uses `FKBadge.defaultConfiguration` when `nil`.
  public init(target: UIView, configuration: FKBadgeConfiguration? = nil) {
    self.targetView = target
    self.configuration = configuration ?? FKBadge.defaultConfiguration
    self.anchor = .topTrailing
    self.offset = .zero
    super.init()
    commonInit()
  }

  private func commonInit() {
    FKBadgeHierarchyObserver.installIfNeeded()
    badgeView.translatesAutoresizingMaskIntoConstraints = false
    badgeView.configuration = configuration
    FKBadgeRegistry.shared.register(self)
    applyConfigurationToBadge()
    applyResolvedContent(animated: false)
  }

  deinit {
    FKBadgeRegistry.shared.unregister(self)
    let v = badgeView
    DispatchQueue.main.async {
      v.removeFromSuperview()
    }
  }

  // MARK: - Public API

  /// Clears content and hides the badge.
  public func clear(animated: Bool = false) {
    perform {
      self.payload = .none
      self.applyResolvedContent(animated: animated)
    }
  }

  /// When `true`, sets `visibilityPolicy` to `.forcedHidden`. When `false`, sets `.automatic` (not `.forcedVisible`).
  public func setForcedHidden(_ hidden: Bool, animated: Bool = false) {
    perform {
      self.visibilityPolicy = hidden ? .forcedHidden : .automatic
      self.applyResolvedContent(animated: animated)
    }
  }

  public func showDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      self.payload = .dot
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Numeric badge with overflow rules from `configuration`. Values `<= 0` hide the badge under `.automatic`.
  public func showCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      self.payload = .count(count)
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Empty or whitespace-only string shows a dot; otherwise shows trimmed text.
  public func showText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      self.payload = trimmed.isEmpty ? .dot : .text(trimmed)
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Parses a digits-only non-negative integer string. Invalid input clears the badge (same as `clear(animated:)` semantics for payload).
  public func setCount(parsing string: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      guard let parsed = FKBadgeFormatter.parseNonNegativeCount(string) else {
        self.payload = .none
        self.applyResolvedContent(animated: animated, entranceAnimation: .none)
        return
      }
      self.payload = .count(parsed)
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  public func setAnchor(_ anchor: FKBadgeAnchor, offset: UIOffset = .zero) {
    perform {
      self.anchor = anchor
      self.offset = offset
    }
  }

  /// Removes the badge from the hierarchy and clears the associated object on the target.
  public func removeFromTarget() {
    perform {
      FKBadgeRegistry.shared.unregister(self)
      self.payload = .none
      self.syncAccessibilityFromResolved()
      self.badgeView.prepareForReuse()
      self.badgeView.removeFromSuperview()
      self.detachAssociatedObject()
    }
  }

  public func reattachIfNeeded() {
    perform {
      self.attachBadgeToParentOfTarget()
      self.rebuildLayoutConstraints()
    }
  }

  /// No-op when the badge is hidden or not in the hierarchy.
  public func playAnimation(_ animation: FKBadgeAnimation) {
    perform {
      guard !self.badgeView.isHidden, self.badgeView.superview != nil else { return }
      self.runEntranceAnimation(animation)
    }
  }

  /// `true` when the badge view is not in the hierarchy or is hidden.
  public var isEffectivelyHidden: Bool {
    if Thread.isMainThread {
      return badgeView.isHidden || badgeView.superview == nil
    }
    var result = false
    DispatchQueue.main.sync {
      result = self.badgeView.isHidden || self.badgeView.superview == nil
    }
    return result
  }

  // MARK: - Internal

  func refreshFromRegistry(animated: Bool) {
    perform {
      self.applyResolvedContent(animated: animated)
    }
  }

  nonisolated static func handleTargetViewMoved(_ view: UIView) {
    guard let controller = objc_getAssociatedObject(view, &FKBadgeAssociatedKeys.controller) as? FKBadgeController else {
      return
    }
    Task { @MainActor in
      controller.reattachIfNeeded()
    }
  }

  // MARK: - Private

  private func resolve() -> (mode: FKBadgeContentView.Mode, shouldShow: Bool) {
    if FKBadgeRegistry.shared.globalSuppressed {
      return (.dot, false)
    }

    if visibilityPolicy == .forcedHidden {
      return (.dot, false)
    }

    let forcedVisible = visibilityPolicy == .forcedVisible

    switch payload {
    case .none:
      return (.dot, false)

    case .dot:
      return (.dot, true)

    case .count(let value):
      if value <= 0 {
        if forcedVisible {
          return (.text("0"), true)
        }
        return (.dot, false)
      }
      guard let text = FKBadgeFormatter.displayString(count: value, configuration: configuration) else {
        return (.dot, false)
      }
      return (.text(text), true)

    case .text(let string):
      return (.text(string), true)
    }
  }

  private func applyConfigurationToBadge() {
    badgeView.configuration = configuration
  }

  private func applyResolvedContent(animated: Bool, entranceAnimation: FKBadgeAnimation = .none) {
    let wasHidden = badgeView.isHidden || badgeView.alpha < 0.01
    let (mode, shouldShow) = resolve()
    let motionAllowed = !UIAccessibility.isReduceMotionEnabled
    let shouldAnimateVisibility = animated && motionAllowed

    if !shouldShow {
      stopRepeatingAnimations()
      badgeView.prepareForReuse()
      badgeView.isHidden = true
      syncAccessibilityFromResolved()
      if shouldAnimateVisibility {
        UIView.animate(withDuration: 0.2) {
          self.badgeView.alpha = 0
        }
      } else {
        badgeView.alpha = 0
      }
      return
    }

    badgeView.mode = mode
    badgeView.isHidden = false
    updateTapGestureState()

    attachBadgeToParentOfTarget()
    rebuildLayoutConstraints()

    if shouldAnimateVisibility, wasHidden {
      badgeView.alpha = 0
      UIView.animate(withDuration: 0.2) {
        self.badgeView.alpha = 1
      } completion: { _ in
        if entranceAnimation != .none {
          self.runEntranceAnimation(entranceAnimation)
        }
      }
    } else {
      badgeView.alpha = 1
      if entranceAnimation != .none {
        runEntranceAnimation(entranceAnimation)
      }
    }
    syncAccessibilityFromResolved()
  }

  private func attachBadgeToParentOfTarget() {
    guard let target = targetView else {
      badgeView.removeFromSuperview()
      return
    }
    guard let parent = target.superview else {
      badgeView.removeFromSuperview()
      DispatchQueue.main.async { [weak self] in
        self?.attachBadgeToParentOfTarget()
        self?.rebuildLayoutConstraints()
      }
      return
    }

    if badgeView.superview !== parent {
      badgeView.removeFromSuperview()
      parent.addSubview(badgeView)
    }
    parent.bringSubviewToFront(badgeView)
    badgeView.layer.zPosition = 10_000
  }

  private func rebuildLayoutConstraints() {
    NSLayoutConstraint.deactivate(layoutConstraints)
    layoutConstraints.removeAll()

    guard let target = targetView, let parent = target.superview, badgeView.superview === parent else {
      return
    }

    let h = offset.horizontal
    let v = offset.vertical

    switch anchor {
    case .topLeading:
      layoutConstraints = [
        badgeView.centerXAnchor.constraint(equalTo: target.leadingAnchor, constant: h),
        badgeView.centerYAnchor.constraint(equalTo: target.topAnchor, constant: v),
      ]
    case .topTrailing:
      layoutConstraints = [
        badgeView.centerXAnchor.constraint(equalTo: target.trailingAnchor, constant: h),
        badgeView.centerYAnchor.constraint(equalTo: target.topAnchor, constant: v),
      ]
    case .bottomLeading:
      layoutConstraints = [
        badgeView.centerXAnchor.constraint(equalTo: target.leadingAnchor, constant: h),
        badgeView.centerYAnchor.constraint(equalTo: target.bottomAnchor, constant: v),
      ]
    case .bottomTrailing:
      layoutConstraints = [
        badgeView.centerXAnchor.constraint(equalTo: target.trailingAnchor, constant: h),
        badgeView.centerYAnchor.constraint(equalTo: target.bottomAnchor, constant: v),
      ]
    case .center:
      layoutConstraints = [
        badgeView.centerXAnchor.constraint(equalTo: target.centerXAnchor, constant: h),
        badgeView.centerYAnchor.constraint(equalTo: target.centerYAnchor, constant: v),
      ]
    }

    NSLayoutConstraint.activate(layoutConstraints)
  }

  private func runEntranceAnimation(_ animation: FKBadgeAnimation) {
    stopRepeatingAnimations()
    badgeView.layer.removeAllAnimations()

    if animation != .none, UIAccessibility.isReduceMotionEnabled {
      return
    }

    switch animation {
    case .none:
      break

    case .pop(let fromScale, let overshoot, let duration):
      badgeView.transform = CGAffineTransform(scaleX: fromScale, y: fromScale)
      UIView.animate(
        withDuration: duration * 0.55,
        delay: 0,
        usingSpringWithDamping: 0.68,
        initialSpringVelocity: 0.6,
        options: [.allowUserInteraction, .beginFromCurrentState]
      ) {
        self.badgeView.transform = CGAffineTransform(scaleX: overshoot, y: overshoot)
      } completion: { _ in
        UIView.animate(withDuration: duration * 0.45) {
          self.badgeView.transform = .identity
        }
      }

    case .blink(let minA, let maxA, let duration):
      badgeView.alpha = maxA
      UIView.animate(
        withDuration: duration,
        delay: 0,
        options: [.repeat, .autoreverse, .allowUserInteraction, .curveEaseInOut]
      ) {
        self.badgeView.alpha = minA
      }

    case .pulse(let scale, let duration):
      let pulse = CABasicAnimation(keyPath: "transform.scale")
      pulse.fromValue = 1
      pulse.toValue = scale
      pulse.duration = duration
      pulse.autoreverses = true
      pulse.repeatCount = .greatestFiniteMagnitude
      pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      badgeView.layer.add(pulse, forKey: "fkbadge_pulse")
    }
  }

  private func stopRepeatingAnimations() {
    badgeView.layer.removeAllAnimations()
  }

  private func updateTapGestureState() {
    if onTap != nil {
      badgeView.minimumTouchTargetSide = minimumTouchTargetSide
      if badgeView.gestureRecognizers?.contains(tapGestureRecognizer) != true {
        badgeView.addGestureRecognizer(tapGestureRecognizer)
      }
      badgeView.isUserInteractionEnabled = true
    } else {
      badgeView.minimumTouchTargetSide = nil
      if badgeView.gestureRecognizers?.contains(tapGestureRecognizer) == true {
        badgeView.removeGestureRecognizer(tapGestureRecognizer)
      }
      badgeView.isUserInteractionEnabled = false
    }
  }

  private func syncAccessibilityFromResolved() {
    let (mode, shouldShow) = resolve()
    guard shouldShow else {
      badgeView.isAccessibilityElement = false
      badgeView.accessibilityLabel = nil
      badgeView.accessibilityTraits = []
      badgeView.accessibilityRespondsToUserInteraction = false
      return
    }

    let trimmed = accessibilityBadgeLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let overrideText = (trimmed?.isEmpty == false) ? trimmed : nil

    let effectiveLabel: String?
    if let overrideText {
      effectiveLabel = overrideText
    } else {
      switch mode {
      case .text(let s): effectiveLabel = s
      case .dot: effectiveLabel = nil
      }
    }

    if let effectiveLabel {
      badgeView.isAccessibilityElement = true
      badgeView.accessibilityLabel = effectiveLabel
      var traits = UIAccessibilityTraits()
      if shouldAnnounceNumericUpdatesFrequently(mode: mode) {
        traits.insert(.updatesFrequently)
      }
      badgeView.accessibilityTraits = traits
    } else {
      badgeView.isAccessibilityElement = false
      badgeView.accessibilityLabel = nil
      badgeView.accessibilityTraits = []
    }
    badgeView.accessibilityRespondsToUserInteraction = (onTap != nil)
  }

  private func shouldAnnounceNumericUpdatesFrequently(mode: FKBadgeContentView.Mode) -> Bool {
    guard case .text(let s) = mode else { return false }
    guard !s.isEmpty else { return false }
    return s.allSatisfy { $0.isNumber || $0 == "+" }
  }

  @objc private func handleBadgeTap() {
    onTap?(self)
  }

  private func detachAssociatedObject() {
    guard let target = targetView else { return }
    objc_setAssociatedObject(target, &FKBadgeAssociatedKeys.controller, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  private nonisolated func perform(_ work: @escaping @MainActor () -> Void) {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        work()
      }
    } else {
      Task { @MainActor in
        work()
      }
    }
  }
}

enum FKBadgeAssociatedKeys {
  nonisolated(unsafe) static var controller: UInt8 = 0
}
