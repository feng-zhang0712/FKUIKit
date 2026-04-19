//
// FKBadgeController.swift
//

import ObjectiveC
import UIKit

/// Hosts a badge as a **sibling** of the target view (never inserted into the target), with constraints tied to the target’s corners.
@MainActor
public final class FKBadgeController: NSObject {
  /// Weak reference to the view this badge decorates.
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

  /// Which corner of `targetView` the badge aligns to (uses leading/trailing for RTL).
  public var anchor: FKBadgeAnchor {
    didSet {
      perform { self.rebuildLayoutConstraints() }
    }
  }

  /// Extra shift from the anchor along horizontal and vertical axes (same coordinate space as constraints).
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

  private let badgeView = FKBadgeContentView()
  private var layoutConstraints: [NSLayoutConstraint] = []

  private enum Payload: Equatable {
    case none
    case dot
    case count(Int)
    case text(String)
  }

  private var payload: Payload = .none

  /// Creates a controller; prefer `UIView.fk_badge` so the instance is associated with the target view.
  public init(target: UIView, configuration: FKBadgeConfiguration? = nil) {
    self.targetView = target
    self.configuration = configuration ?? FKBadge.defaultConfiguration
    self.anchor = .topTrailing
    self.offset = .zero
    super.init()
    commonInit()
  }

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

  /// Pure red dot (no text).
  public func showDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    perform {
      self.payload = .dot
      self.applyResolvedContent(animated: animated, entranceAnimation: animation)
    }
  }

  /// Numeric badge with overflow rules from `configuration`.
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

  /// Parses a decimal string; invalid values hide the badge.
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
        badgeView.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: h),
        badgeView.topAnchor.constraint(equalTo: target.topAnchor, constant: v),
      ]
    case .topTrailing:
      layoutConstraints = [
        badgeView.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: h),
        badgeView.topAnchor.constraint(equalTo: target.topAnchor, constant: v),
      ]
    case .bottomLeading:
      layoutConstraints = [
        badgeView.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: h),
        badgeView.bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: v),
      ]
    case .bottomTrailing:
      layoutConstraints = [
        badgeView.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: h),
        badgeView.bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: v),
      ]
    }

    NSLayoutConstraint.activate(layoutConstraints)
  }

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

  private func stopRepeatingAnimations() {
    badgeView.layer.removeAllAnimations()
  }

  private func detachAssociatedObject() {
    guard let target = targetView else { return }
    objc_setAssociatedObject(target, &FKBadgeAssociatedKeys.controller, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  private func perform(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }
}

// MARK: - Associated object

enum FKBadgeAssociatedKeys {
  nonisolated(unsafe) static var controller: UInt8 = 0
}
