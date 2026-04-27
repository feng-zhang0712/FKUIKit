import ObjectiveC
import UIKit

/// Hosts a badge as a **sibling** of the target view (never inserted into the target), with constraints tied to the target’s anchors.
@MainActor
public final class FKBadgeController: NSObject {
  /// Weak reference to the view this badge decorates.
  ///
  /// `weak` avoids retain cycles because the controller is often associated to the same view.
  public private(set) weak var targetView: UIView?

  /// Visual styling; updates apply immediately to the badge view.
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
  /// - Important: Alignment is **center-based**. For corner anchors, the target’s corner is aligned to the
  ///   badge view’s **center** (not the badge view’s corner). Use `offset` to fine-tune placement.
  public var anchor: FKBadgeAnchor {
    didSet {
      perform { self.rebuildLayoutConstraints() }
    }
  }

  /// Extra shift from the anchor point along horizontal and vertical axes.
  ///
  /// Positive/negative direction follows Auto Layout constant semantics for the selected anchor constraints.
  public var offset: UIOffset {
    didSet {
      perform { self.rebuildLayoutConstraints() }
    }
  }

  /// Overrides automatic hide/show rules (e.g. force-hide badges during onboarding).
  public var visibilityPolicy: FKBadgeVisibilityPolicy = .automatic {
    didSet {
      perform { self.applyResolvedContent(animated: false) }
    }
  }

  /// Called when the badge view is tapped.
  ///
  /// Keep captures weak when referencing owning objects to avoid retain cycles.
  public var onTap: ((FKBadgeController) -> Void)? {
    didSet {
      perform { self.updateTapGestureState() }
    }
  }

  // Rendering host reused for all payload transitions.
  private let badgeView = FKBadgeContentView()
  // Gesture is attached only when `onTap` is non-nil.
  private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBadgeTap))
  // Active constraints between badge and target; rebuilt when anchor/offset/parent changes.
  private var layoutConstraints: [NSLayoutConstraint] = []

  // Internal normalized content source before visibility resolution.
  private enum Payload: Equatable {
    case none
    case dot
    case count(Int)
    case text(String)
  }

  private var payload: Payload = .none

  /// Creates a controller; prefer `UIView.fk_badge` so the instance is associated with the target view.
  ///
  /// - Parameters:
  ///   - target: Decorated view. Badge is attached to `target.superview`, not into `target`.
  ///   - configuration: Optional initial style. Uses global manager defaults when `nil`.
  public init(target: UIView, configuration: FKBadgeConfiguration? = nil) {
    self.targetView = target
    self.configuration = configuration ?? FKBadgeManager.shared.defaultConfiguration
    self.anchor = .topTrailing
    self.offset = .zero
    super.init()
    commonInit()
  }

  // Shared setup for all constructors.
  private func commonInit() {
    FKBadgeUIViewSwizzling.installIfNeeded()
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

  /// Updates hidden state without changing current payload.
  public func setHidden(_ hidden: Bool, animated: Bool = false) {
    perform {
      self.visibilityPolicy = hidden ? .forcedHidden : .automatic
      self.applyResolvedContent(animated: animated)
    }
  }

  /// Convenience alias for updating numeric content.
  ///
  /// - Parameters:
  ///   - count: New count value.
  ///   - animated: Whether to fade when transitioning from hidden to visible.
  ///   - animation: Optional entrance/replay animation.
  public func updateCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    showCount(count, animated: animated, animation: animation)
  }

  /// Convenience API to clear numeric badge (count to zero).
  public func clearCount(animated: Bool = false) {
    showCount(0, animated: animated, animation: .none)
  }

  /// Pure red dot (no text).
  ///
  /// - Parameters:
  ///   - animated: Whether to fade-in from hidden state.
  ///   - animation: Optional emphasis animation after showing.
  public func showDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      self.payload = .dot
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Numeric badge with overflow rules from `configuration`.
  ///
  /// - Parameters:
  ///   - count: Raw count. Values `<= 0` are hidden under `.automatic`.
  ///   - animated: Whether to fade-in from hidden state.
  ///   - animation: Optional emphasis animation after showing.
  public func showCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      self.payload = .count(count)
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Empty or whitespace-only string shows a dot; otherwise shows trimmed text.
  ///
  /// - Parameters:
  ///   - text: Raw text input; whitespace-only input is normalized to dot mode.
  ///   - animated: Whether to fade-in from hidden state.
  ///   - animation: Optional emphasis animation after showing.
  public func showText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      self.payload = trimmed.isEmpty ? .dot : .text(trimmed)
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Parses a decimal string; invalid values hide the badge.
  ///
  /// - Parameters:
  ///   - string: User/server string input.
  ///   - animated: Whether to animate show/hide transition.
  ///   - animation: Animation used when parsing succeeds.
  public func showCountString(_ string: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
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

  /// Updates anchor and offset together.
  ///
  /// - Parameters:
  ///   - anchor: Layout anchor in target coordinates.
  ///   - offset: Additional x/y shift from the anchor point.
  public func setAnchor(_ anchor: FKBadgeAnchor, offset: UIOffset = .zero) {
    perform {
      self.anchor = anchor
      self.offset = offset
    }
  }

  /// Removes the badge from the hierarchy and detaches the associated object from the target.
  public func removeFromTarget() {
    perform {
      FKBadgeRegistry.shared.unregister(self)
      self.payload = .none
      self.badgeView.prepareForReuse()
      self.badgeView.removeFromSuperview()
      self.detachAssociatedObject()
    }
  }

  /// Re-runs layout attachment (for example after manually changing the target’s superview).
  public func reattachIfNeeded() {
    perform {
      self.attachBadgeToParentOfTarget()
      self.rebuildLayoutConstraints()
    }
  }

  /// Replays an animation on the currently visible badge.
  ///
  /// - Note: No-op when badge is hidden or detached from hierarchy.
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

  // Called by registry on global hide/restore broadcasts.
  func refreshFromRegistry(animated: Bool) {
    perform {
      self.applyResolvedContent(animated: animated)
    }
  }

  /// `UIView.didMoveToSuperview` always runs on the main thread; keep this path nonisolated for the ObjC runtime hook.
  nonisolated static func handleTargetViewMoved(_ view: UIView) {
    guard let controller = objc_getAssociatedObject(view, &FKBadgeAssociatedKeys.controller) as? FKBadgeController else {
      return
    }
    Task { @MainActor in
      controller.reattachIfNeeded()
    }
  }

  // MARK: - Private

  // Resolves final visual mode and visibility using payload + policies.
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

  // Pushes style changes into the render view.
  private func applyConfigurationToBadge() {
    badgeView.configuration = configuration
  }

  // Applies resolved payload to view state and performs show/hide transitions.
  private func applyResolvedContent(animated: Bool, entranceAnimation: FKBadgeAnimation = .none) {
    let wasHidden = badgeView.isHidden || badgeView.alpha < 0.01
    let (mode, shouldShow) = resolve()

    if !shouldShow {
      stopRepeatingAnimations()
      badgeView.prepareForReuse()
      badgeView.isHidden = true
      if animated {
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

    if animated, wasHidden {
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
  }

  // Ensures badge is attached to target's parent so target's own clipping/hit-testing remain unchanged.
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

  // Rebuilds geometric attachment constraints from current anchor + offset.
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

  // Runs one-shot or repeating visual emphasis.
  private func runEntranceAnimation(_ animation: FKBadgeAnimation) {
    stopRepeatingAnimations()
    badgeView.layer.removeAllAnimations()

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
      badgeView.layer.add(pulse, forKey: "fk_badge_pulse")
    }
  }

  // Stops any repeating layer/view animations before mode changes.
  private func stopRepeatingAnimations() {
    badgeView.layer.removeAllAnimations()
  }

  // Installs or removes tap recognizer based on callback presence.
  private func updateTapGestureState() {
    if onTap != nil {
      if badgeView.gestureRecognizers?.contains(tapGestureRecognizer) != true {
        badgeView.addGestureRecognizer(tapGestureRecognizer)
      }
      badgeView.isUserInteractionEnabled = true
    } else {
      if badgeView.gestureRecognizers?.contains(tapGestureRecognizer) == true {
        badgeView.removeGestureRecognizer(tapGestureRecognizer)
      }
      badgeView.isUserInteractionEnabled = false
    }
  }

  // Forwards tap events to the public callback.
  @objc private func handleBadgeTap() {
    onTap?(self)
  }

  // Clears associated object reference when controller is explicitly removed.
  private func detachAssociatedObject() {
    guard let target = targetView else { return }
    objc_setAssociatedObject(target, &FKBadgeAssociatedKeys.controller, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  // Main-thread trampoline for APIs that might be called off-main.
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

// MARK: - Associated object

enum FKBadgeAssociatedKeys {
  // ObjC runtime key for `UIView` associated `FKBadgeController`.
  nonisolated(unsafe) static var controller: UInt8 = 0
}
