import UIKit

/// Animator that drives presentation and dismissal transitions based on `FKPresentationMode`.
final class FKPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  private let isPresentation: Bool
  private let mode: FKPresentationMode
  private let animationConfiguration: FKAnimationConfiguration
  private var cachedAnimator: UIViewImplicitlyAnimating?

  init(
    isPresentation: Bool,
    mode: FKPresentationMode,
    animationConfiguration: FKAnimationConfiguration
  ) {
    self.isPresentation = isPresentation
    self.mode = mode
    self.animationConfiguration = animationConfiguration
    super.init()
  }

  func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
    let style = FKAnimationStyleResolver.resolveTransitionStyle(
      mode: mode,
      animationConfiguration: animationConfiguration,
      isPresentation: isPresentation,
      reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
      interactionState: .nonInteractive
    )
    return max(0, style.duration)
  }

  func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    // Always go through the interruptible animator so interactive dismiss can drive progress smoothly.
    let animator = interruptibleAnimator(using: transitionContext)
    animator.startAnimation()
  }

  func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
    if let cachedAnimator { return cachedAnimator }
    let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from
    guard let controller = transitionContext.viewController(forKey: key) else {
      transitionContext.completeTransition(false)
      let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
      cachedAnimator = fallback
      return fallback
    }

    let containerView = transitionContext.containerView
    let animatingView: UIView

    if isPresentation {
      guard let toView = transitionContext.view(forKey: .to) else {
        transitionContext.completeTransition(false)
        let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
        cachedAnimator = fallback
        return fallback
      }
      containerView.addSubview(toView)
      animatingView = toView
    } else {
      guard let fromView = transitionContext.view(forKey: .from) else {
        transitionContext.completeTransition(false)
        let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
        cachedAnimator = fallback
        return fallback
      }
      animatingView = fromView
    }

    // UIKit contract:
    // - Presentation: use `finalFrame(for: toVC)`
    // - Dismissal: use `initialFrame(for: fromVC)` as the baseline to compute exit frames
    let baseFrame = isPresentation
      ? transitionContext.finalFrame(for: controller)
      : transitionContext.initialFrame(for: controller)

    let style = FKAnimationStyleResolver.resolveTransitionStyle(
      mode: mode,
      animationConfiguration: animationConfiguration,
      isPresentation: isPresentation,
      reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
      interactionState: transitionContext.isInteractive ? .interactive : .nonInteractive
    )
    let start = initialState(for: baseFrame, style: style)
    let end = finalState(for: baseFrame, style: style)

    if isPresentation {
      apply(state: start, to: animatingView)
    }

    if animationConfiguration.preset == .none || style.duration == 0 {
      apply(state: isPresentation ? end : start, to: animatingView)
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
      cachedAnimator = fallback
      return fallback
    }

    let context = FKAnimationContext(
      isPresentation: isPresentation,
      mode: mode,
      animatingView: animatingView,
      startFrame: start.frame,
      endFrame: end.frame
    )

    let animator = makePropertyAnimator(
      style: style,
      context: context,
      animations: { [weak self] in
        guard let self else { return }
        if self.isPresentation {
          self.apply(state: end, to: animatingView)
        } else {
          self.apply(state: start, to: animatingView)
        }
      }
    )
    animator.addCompletion { position in
      // `transitionWasCancelled` is the source of truth for interactive cancellations. Using it keeps
      // host cleanup and callback order consistent between finish/cancel outcomes.
      let finished = (position == .end || position == .current) && !transitionContext.transitionWasCancelled
      transitionContext.completeTransition(finished)
      self.cachedAnimator = nil
    }
    cachedAnimator = animator
    return animator
  }

  private struct State {
    var frame: CGRect
    var alpha: CGFloat
    var transform: CGAffineTransform
  }

  private func initialState(for baseFrame: CGRect, style: FKAnimationStyleResolver.TransitionStyle) -> State {
    // Center keeps frame stable and communicates motion with subtle scale+alpha.
    // Sheet-like families start from an offset frame to preserve directional attachment cues.
    let frame = style.family == .alertLikeCenter ? baseFrame : initialFrame(for: baseFrame)
    return .init(
      frame: frame,
      alpha: style.initialAlpha,
      transform: CGAffineTransform(scaleX: style.initialScale, y: style.initialScale)
    )
  }

  private func finalState(for baseFrame: CGRect, style: FKAnimationStyleResolver.TransitionStyle) -> State {
    return .init(
      frame: baseFrame,
      alpha: style.finalAlpha,
      transform: CGAffineTransform(scaleX: style.finalScale, y: style.finalScale)
    )
  }

  private func apply(state: State, to view: UIView) {
    view.frame = state.frame
    view.alpha = state.alpha
    view.transform = state.transform
  }

  private func initialFrame(for baseFrame: CGRect) -> CGRect {
    switch mode {
    case .bottomSheet:
      return baseFrame.offsetBy(dx: 0, dy: baseFrame.height)
    case .topSheet:
      return baseFrame.offsetBy(dx: 0, dy: -baseFrame.height)
    case .center:
      return baseFrame
    case let .anchor(anchor):
      // Anchor animations should follow the expansion direction to avoid “always from bottom” awkwardness.
      let delta: CGFloat = 12
      switch anchor.direction {
      case .up:
        return baseFrame.offsetBy(dx: 0, dy: delta)
      case .down:
        return baseFrame.offsetBy(dx: 0, dy: -delta)
      case .auto:
        // When auto, use attachment edge as a reasonable hint.
        switch anchor.edge {
        case .top:
          return baseFrame.offsetBy(dx: 0, dy: -delta)
        case .bottom:
          return baseFrame.offsetBy(dx: 0, dy: delta)
        }
      }
    case let .anchorEmbedded(configuration):
      // Embedded anchors use the same motion baseline as modal anchors.
      return initialFrame(for: baseFrame, anchor: configuration.anchor)
    case let .edge(edge):
      if edge.contains(.left) { return baseFrame.offsetBy(dx: -baseFrame.width, dy: 0) }
      if edge.contains(.right) { return baseFrame.offsetBy(dx: baseFrame.width, dy: 0) }
      if edge.contains(.top) { return baseFrame.offsetBy(dx: 0, dy: -baseFrame.height) }
      return baseFrame.offsetBy(dx: 0, dy: baseFrame.height)
    }
  }

  private func initialFrame(for baseFrame: CGRect, anchor: FKAnchor) -> CGRect {
    let delta: CGFloat = 12
    switch anchor.direction {
    case .up:
      return baseFrame.offsetBy(dx: 0, dy: delta)
    case .down:
      return baseFrame.offsetBy(dx: 0, dy: -delta)
    case .auto:
      switch anchor.edge {
      case .top:
        return baseFrame.offsetBy(dx: 0, dy: -delta)
      case .bottom:
        return baseFrame.offsetBy(dx: 0, dy: delta)
      }
    }
  }

  private func makePropertyAnimator(
    style: FKAnimationStyleResolver.TransitionStyle,
    context: FKAnimationContext,
    animations: @escaping () -> Void
  ) -> UIViewPropertyAnimator {
    if let custom = animationConfiguration.customPropertyAnimator?(context) {
      custom.addAnimations(animations)
      return custom
    }

    switch style.timing {
    case let .spring(dampingRatio):
      let params = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: .zero)
      return UIViewPropertyAnimator(duration: style.duration, timingParameters: params).addingAnimations(animations)
    case let .curve(curve):
      if animationConfiguration.preset == .easeInOut, let timingCurve = animationConfiguration.timingCurve {
        return UIViewPropertyAnimator(duration: style.duration, timingParameters: timingCurve).addingAnimations(animations)
      }
      return UIViewPropertyAnimator(duration: style.duration, curve: curve, animations: animations)
    }
  }
}

private extension UIViewPropertyAnimator {
  func addingAnimations(_ block: @escaping () -> Void) -> UIViewPropertyAnimator {
    addAnimations(block)
    return self
  }
}

// MARK: - Mode-aware animation resolver

/// Resolves mode-aware animation styles for FK presentation transitions.
///
/// This lives in the animator file intentionally so it is always compiled into the FKUIKit target
/// even when the Xcode project uses an explicit file list (instead of directory-based discovery).
enum FKAnimationStyleResolver {
  enum Family {
    case alertLikeCenter
    case sheetLike
  }

  enum InteractionState {
    case nonInteractive
    case interactive
  }

  struct TransitionStyle {
    let family: Family
    let duration: TimeInterval
    let timing: Timing
    let initialAlpha: CGFloat
    let finalAlpha: CGFloat
    let initialScale: CGFloat
    let finalScale: CGFloat
  }

  enum Timing {
    case spring(dampingRatio: CGFloat)
    case curve(UIView.AnimationCurve)
  }

  static func resolveTransitionStyle(
    mode: FKPresentationMode,
    animationConfiguration: FKAnimationConfiguration,
    isPresentation: Bool,
    reduceMotionEnabled: Bool,
    interactionState: InteractionState
  ) -> TransitionStyle {
    if animationConfiguration.preset == .none {
      return .init(
        family: family(for: mode),
        duration: 0,
        timing: .curve(.linear),
        initialAlpha: 1,
        finalAlpha: 1,
        initialScale: 1,
        finalScale: 1
      )
    }

    let family = family(for: mode)

    if reduceMotionEnabled {
      // Reduce Motion: keep movement minimal; fade is the primary signal.
      let scale: CGFloat
      if family == .alertLikeCenter {
        scale = isPresentation ? 0.985 : 0.97
      } else {
        scale = 1
      }
      return .init(
        family: family,
        duration: min(0.2, max(0, animationConfiguration.duration)),
        timing: .curve(.easeInOut),
        initialAlpha: isPresentation ? 0 : 1,
        finalAlpha: isPresentation ? 1 : 0,
        initialScale: scale,
        finalScale: 1
      )
    }

    switch family {
    case .alertLikeCenter:
      return resolveAlertLikeCenterStyle(
        animationConfiguration: animationConfiguration,
        isPresentation: isPresentation,
        interactionState: interactionState
      )
    case .sheetLike:
      return resolveSheetLikeStyle(
        animationConfiguration: animationConfiguration,
        isPresentation: isPresentation,
        interactionState: interactionState
      )
    }
  }

  private static func resolveAlertLikeCenterStyle(
    animationConfiguration: FKAnimationConfiguration,
    isPresentation: Bool,
    interactionState: InteractionState
  ) -> TransitionStyle {
    // Target feel: UIAlertController(.alert)-like.
    let initialScale: CGFloat = isPresentation ? 0.95 : 1
    let finalScale: CGFloat = isPresentation ? 1 : 0.97
    let initialAlpha: CGFloat = isPresentation ? 0 : 1
    let finalAlpha: CGFloat = isPresentation ? 1 : 0

    let duration: TimeInterval
    let timing: Timing

    switch animationConfiguration.preset {
    case .systemLike:
      duration = isPresentation ? 0.26 : 0.22
      // System alert tends to ease out on present and ease in on dismiss.
      timing = .curve(isPresentation ? .easeOut : .easeIn)
    case .spring:
      duration = max(0.22, min(0.3, animationConfiguration.duration))
      timing = .spring(dampingRatio: min(max(animationConfiguration.dampingRatio, 0.84), 0.95))
    case .easeInOut:
      duration = max(0.2, min(0.3, animationConfiguration.duration))
      timing = .curve(isPresentation ? .easeOut : .easeIn)
    case .fade:
      duration = isPresentation ? 0.22 : 0.18
      timing = .curve(.linear)
    case .none:
      duration = 0
      timing = .curve(.linear)
    }

    // Interactive center dismiss should stay “modal card”, not “sheet drag”.
    let adjustedDuration = interactionState == .interactive && !isPresentation ? min(duration, 0.2) : duration

    return .init(
      family: .alertLikeCenter,
      duration: adjustedDuration,
      timing: timing,
      initialAlpha: initialAlpha,
      finalAlpha: finalAlpha,
      initialScale: initialScale,
      finalScale: finalScale
    )
  }

  private static func resolveSheetLikeStyle(
    animationConfiguration: FKAnimationConfiguration,
    isPresentation: Bool,
    interactionState: InteractionState
  ) -> TransitionStyle {
    // Target feel: UISheetPresentationController-like.
    let duration: TimeInterval
    let timing: Timing

    switch animationConfiguration.preset {
    case .systemLike:
      duration = isPresentation ? 0.36 : 0.28
      timing = .spring(dampingRatio: 0.9)
    case .spring:
      let clamped = max(0.3, min(0.42, animationConfiguration.duration))
      duration = isPresentation ? clamped : max(0.22, clamped * 0.82)
      timing = .spring(dampingRatio: min(max(animationConfiguration.dampingRatio, 0.8), 0.95))
    case .easeInOut:
      let clamped = max(0.24, min(0.38, animationConfiguration.duration))
      duration = isPresentation ? clamped : max(0.22, clamped * 0.82)
      timing = .curve(.easeInOut)
    case .fade:
      duration = isPresentation ? 0.24 : 0.2
      timing = .curve(.linear)
    case .none:
      duration = 0
      timing = .curve(.linear)
    }

    let adjustedDuration = interactionState == .interactive && !isPresentation ? min(duration, 0.26) : duration
    return .init(
      family: .sheetLike,
      duration: adjustedDuration,
      timing: timing,
      initialAlpha: 1,
      finalAlpha: 1,
      initialScale: 1,
      finalScale: 1
    )
  }

  private static func family(for mode: FKPresentationMode) -> Family {
    if case .center = mode { return .alertLikeCenter }
    return .sheetLike
  }
}

