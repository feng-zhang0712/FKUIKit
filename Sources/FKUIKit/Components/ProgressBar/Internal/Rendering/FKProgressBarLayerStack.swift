import QuartzCore
import UIKit

/// Owns all `CALayer` subtrees for ``FKProgressBar`` (linear + ring).
final class FKProgressBarLayerStack {
  let container = CALayer()
  private let trackLayer = CAShapeLayer()
  private let bufferHost = CALayer()
  private let bufferFill = CALayer()
  private let bufferMask = CALayer()
  private let progressHost = CALayer()
  private let progressGradient = CAGradientLayer()
  private let progressMask = CALayer()
  private let progressBorder = CAShapeLayer()
  /// Clips the indeterminate marquee capsule to the linear track so it cannot draw outside the bar.
  private let linearMarqueeClipHost = CALayer()
  private let marqueeCapsule = CALayer()
  private let ringBuffer = CAShapeLayer()
  private let ringTrack = CAShapeLayer()
  private let ringProgress = CAShapeLayer()
  private let ringMarquee = CAShapeLayer()
  let animator = FKProgressBarIndeterminateAnimator()

  func install() {
    container.addSublayer(trackLayer)
    container.addSublayer(bufferHost)
    bufferHost.addSublayer(bufferFill)
    bufferFill.mask = bufferMask
    container.addSublayer(progressHost)
    progressHost.addSublayer(progressGradient)
    progressGradient.mask = progressMask
    container.addSublayer(progressBorder)
    container.addSublayer(linearMarqueeClipHost)
    linearMarqueeClipHost.addSublayer(marqueeCapsule)
    container.addSublayer(ringBuffer)
    container.addSublayer(ringTrack)
    container.addSublayer(ringProgress)
    container.addSublayer(ringMarquee)
    animator.attach(marquee: marqueeCapsule, ringRotation: ringMarquee)

    bufferFill.backgroundColor = UIColor.clear.cgColor
    progressBorder.fillColor = UIColor.clear.cgColor
    [ringBuffer, ringTrack, ringProgress, ringMarquee].forEach {
      $0.fillColor = UIColor.clear.cgColor
      $0.strokeStart = 0
      $0.lineJoin = .round
    }
    ringMarquee.lineCap = .round
    ringProgress.lineCap = .round
    ringBuffer.lineCap = .round
    ringTrack.lineCap = .round
    marqueeCapsule.masksToBounds = true
  }

  func layout(
    in bounds: CGRect,
    configuration: FKProgressBarConfiguration,
    progress: CGFloat,
    buffer: CGFloat,
    isIndeterminate: Bool,
    layoutDirection: UIUserInterfaceLayoutDirection,
    traitCollection: UITraitCollection,
    reducedMotion: Bool,
    animated: Bool,
    animationDuration: TimeInterval,
    timing: FKProgressBarTiming,
    prefersSpring: Bool,
    springDamping: CGFloat,
    springVelocity: CGFloat
  ) {
    container.frame = bounds
    let trackRect = FKProgressBarLayoutEngine.trackRect(in: bounds, contentInsets: configuration.layout.contentInsets)
    let disableActions = !animated || animationDuration <= 0 || (reducedMotion && configuration.motion.respectsReducedMotion)
    CATransaction.begin()
    CATransaction.setDisableActions(disableActions)
    if !disableActions {
      CATransaction.setAnimationDuration(animationDuration)
      CATransaction.setAnimationTimingFunction(timing.mediaTimingFunction())
    }

    switch configuration.layout.variant {
    case .linear:
      layoutLinear(
        trackRect: trackRect,
        configuration: configuration,
        progress: progress,
        buffer: buffer,
        isIndeterminate: isIndeterminate,
        layoutDirection: layoutDirection,
        reducedMotion: reducedMotion,
        disableActions: disableActions,
        prefersSpring: prefersSpring,
        springDamping: springDamping,
        springVelocity: springVelocity,
        animationDuration: animationDuration
      )
      hideRingLayers()
    case .ring:
      layoutRing(
        in: trackRect,
        configuration: configuration,
        progress: progress,
        buffer: buffer,
        isIndeterminate: isIndeterminate,
        reducedMotion: reducedMotion,
        disableActions: disableActions,
        traitCollection: traitCollection
      )
      hideLinearLayers()
    }

    CATransaction.commit()
  }

  private func hideRingLayers() {
    ringBuffer.isHidden = true
    ringTrack.isHidden = true
    ringProgress.isHidden = true
    ringMarquee.isHidden = true
  }

  private func hideLinearLayers() {
    trackLayer.isHidden = true
    bufferHost.isHidden = true
    progressHost.isHidden = true
    progressBorder.isHidden = true
    linearMarqueeClipHost.isHidden = true
    marqueeCapsule.isHidden = true
  }

  private func layoutLinear(
    trackRect: CGRect,
    configuration: FKProgressBarConfiguration,
    progress: CGFloat,
    buffer: CGFloat,
    isIndeterminate: Bool,
    layoutDirection: UIUserInterfaceLayoutDirection,
    reducedMotion: Bool,
    disableActions: Bool,
    prefersSpring: Bool,
    springDamping: CGFloat,
    springVelocity: CGFloat,
    animationDuration: TimeInterval
  ) {
    ringBuffer.isHidden = true
    ringTrack.isHidden = true
    ringProgress.isHidden = true
    ringMarquee.isHidden = true

    trackLayer.isHidden = false
    bufferHost.isHidden = !configuration.appearance.showsBuffer
    progressHost.isHidden = false
    progressBorder.isHidden = configuration.appearance.progressBorderWidth <= 0
    linearMarqueeClipHost.isHidden = false
    linearMarqueeClipHost.frame = trackRect
    linearMarqueeClipHost.masksToBounds = true
    linearMarqueeClipHost.backgroundColor = UIColor.clear.cgColor
    trackLayer.opacity = 1
    progressHost.opacity = 1
    bufferHost.opacity = 1

    let corner = resolvedCornerRadius(configuration: configuration, track: trackRect)
    linearMarqueeClipHost.cornerRadius = configuration.layout.segmentCount > 1 ? 0 : (configuration.layout.linearCapStyle == .round ? corner : 0)
    let pathTrack: CGPath
    if configuration.layout.segmentCount > 1,
       let segPath = FKProgressBarLayoutEngine.linearTrackSegmentedPath(track: trackRect, configuration: configuration, layoutDirection: layoutDirection)
    {
      pathTrack = segPath
    } else {
      pathTrack = FKProgressBarLayoutEngine.linearContinuousRoundedPath(in: trackRect, cornerRadius: corner)
    }

    trackLayer.frame = trackRect
    trackLayer.path = pathTrack
    trackLayer.fillColor = configuration.appearance.trackColor.cgColor
    let borderW = configuration.appearance.trackBorderWidth
    trackLayer.lineWidth = borderW > 0 ? borderW : 0
    trackLayer.strokeColor = borderW > 0 ? configuration.appearance.trackBorderColor.cgColor : UIColor.clear.cgColor

    bufferHost.frame = trackRect
    bufferFill.frame = bufferHost.bounds
    bufferFill.backgroundColor = configuration.appearance.bufferColor.cgColor
    bufferFill.cornerRadius = corner

    progressHost.frame = trackRect
    progressGradient.frame = progressHost.bounds
    applyGradient(configuration: configuration, layoutDirection: layoutDirection, in: progressGradient.bounds.size)

    let p = min(max(progress, 0), 1)
    let b = min(max(buffer, 0), 1)

    if configuration.layout.segmentCount <= 1 {
      progressGradient.mask = progressMask
      bufferFill.mask = bufferMask
    }

    if configuration.layout.segmentCount > 1 {
      applySegmentedMasks(
        track: trackRect,
        configuration: configuration,
        progress: p,
        buffer: b,
        layoutDirection: layoutDirection,
        corner: corner
      )
    } else {
      applyScaleMask(
        mask: bufferMask,
        fraction: b,
        axis: configuration.layout.axis,
        layoutDirection: layoutDirection,
        in: bufferHost.bounds,
        disableActions: disableActions,
        prefersSpring: prefersSpring,
        springDamping: springDamping,
        springVelocity: springVelocity,
        animationDuration: animationDuration
      )
      applyScaleMask(
        mask: progressMask,
        fraction: p,
        axis: configuration.layout.axis,
        layoutDirection: layoutDirection,
        in: progressHost.bounds,
        disableActions: disableActions,
        prefersSpring: prefersSpring,
        springDamping: springDamping,
        springVelocity: springVelocity,
        animationDuration: animationDuration
      )
    }

    progressBorder.frame = trackRect
    progressBorder.path = progressBorderPath(
      track: trackRect,
      configuration: configuration,
      progress: p,
      buffer: b,
      layoutDirection: layoutDirection,
      corner: corner
    )
    progressBorder.lineWidth = configuration.appearance.progressBorderWidth
    progressBorder.strokeColor = configuration.appearance.progressBorderColor.cgColor

    let effectiveReduced = reducedMotion && configuration.motion.respectsReducedMotion
    let indeterminateState = isIndeterminate && configuration.motion.indeterminateStyle != .none
    let playsIndeterminateMotion = configuration.motion.playsIndeterminateAnimation
    if indeterminateState, !effectiveReduced {
      progressHost.opacity = configuration.motion.indeterminateStyle == .marquee ? 0.35 : 1
      bufferHost.opacity = 0.35
      trackLayer.opacity = configuration.motion.indeterminateStyle == .breathing ? 1 : 0.9
    } else {
      progressHost.opacity = 1
      bufferHost.opacity = 1
      trackLayer.opacity = 1
    }

    // Marquee / breathing
    animator.stopAll()
    marqueeCapsule.isHidden = true
    if indeterminateState, playsIndeterminateMotion {
      switch configuration.motion.indeterminateStyle {
      case .none:
        break
      case .marquee:
        marqueeCapsule.isHidden = effectiveReduced
        marqueeCapsule.backgroundColor = configuration.appearance.progressColor.cgColor
        let marqueeTrackLocal = CGRect(
          x: 0,
          y: 0,
          width: max(1, trackRect.width),
          height: max(1, trackRect.height)
        )
        animator.startMarqueeLinear(
          period: configuration.motion.indeterminatePeriod,
          trackBounds: marqueeTrackLocal,
          axis: configuration.layout.axis,
          reducedMotion: effectiveReduced
        )
      case .breathing:
        animator.startBreathing(layers: [trackLayer], period: configuration.motion.indeterminatePeriod, reducedMotion: effectiveReduced)
      }
    }

    if indeterminateState, configuration.motion.indeterminateStyle == .marquee, playsIndeterminateMotion {
      progressMask.opacity = 0.01
      bufferMask.opacity = 0.01
    } else {
      progressMask.opacity = 1
      bufferMask.opacity = 1
    }
  }

  private func applySegmentedMasks(
    track: CGRect,
    configuration: FKProgressBarConfiguration,
    progress: CGFloat,
    buffer: CGFloat,
    layoutDirection: UIUserInterfaceLayoutDirection,
    corner: CGFloat
  ) {
    let fp = FKProgressBarLayoutEngine.filledSegmentIndex(progress: progress, segmentCount: configuration.layout.segmentCount)
    let fb = FKProgressBarLayoutEngine.filledSegmentIndex(progress: buffer, segmentCount: configuration.layout.segmentCount)
    let maskFrame = CGRect(origin: .zero, size: track.size)
    if let pathP = FKProgressBarLayoutEngine.linearSegmentUnionPath(track: track, configuration: configuration, filledSegments: fp, layoutDirection: layoutDirection) {
      let shape = CAShapeLayer()
      shape.frame = maskFrame
      shape.path = pathP
      shape.fillColor = UIColor.black.cgColor
      progressGradient.mask = shape
    }
    if configuration.appearance.showsBuffer,
       let pathB = FKProgressBarLayoutEngine.linearSegmentUnionPath(track: track, configuration: configuration, filledSegments: fb, layoutDirection: layoutDirection)
    {
      let shapeB = CAShapeLayer()
      shapeB.frame = maskFrame
      shapeB.path = pathB
      shapeB.fillColor = UIColor.black.cgColor
      bufferFill.mask = shapeB
    }
  }

  private func applyScaleMask(
    mask: CALayer,
    fraction: CGFloat,
    axis: FKProgressBarAxis,
    layoutDirection: UIUserInterfaceLayoutDirection,
    in hostBounds: CGRect,
    disableActions: Bool,
    prefersSpring: Bool,
    springDamping: CGFloat,
    springVelocity: CGFloat,
    animationDuration: TimeInterval
  ) {
    let t = min(max(fraction, 0), 1)
    mask.bounds = CGRect(x: 0, y: 0, width: hostBounds.width, height: hostBounds.height)
    mask.backgroundColor = UIColor.black.cgColor

    let target: CATransform3D
    let springKeyPath: String
    switch axis {
    case .horizontal:
      let isRTL = layoutDirection == .rightToLeft
      mask.anchorPoint = CGPoint(x: isRTL ? 1 : 0, y: 0.5)
      mask.position = CGPoint(x: isRTL ? hostBounds.width : 0, y: hostBounds.midY)
      target = CATransform3DMakeScale(t, 1, 1)
      springKeyPath = "transform.scale.x"
    case .vertical:
      mask.anchorPoint = CGPoint(x: 0.5, y: 1)
      mask.position = CGPoint(x: hostBounds.midX, y: hostBounds.height)
      target = CATransform3DMakeScale(1, t, 1)
      springKeyPath = "transform.scale.y"
    }

    if disableActions || !prefersSpring {
      mask.transform = target
      return
    }

    let spring = CASpringAnimation(keyPath: springKeyPath)
    if let presented = mask.presentation()?.value(forKeyPath: springKeyPath) as? CGFloat {
      spring.fromValue = presented
    } else if let base = (mask.value(forKeyPath: springKeyPath) as? NSNumber)?.floatValue {
      spring.fromValue = CGFloat(base)
    } else {
      spring.fromValue = t
    }
    spring.toValue = t
    spring.stiffness = 380
    spring.damping = 24 * Double(springDamping)
    spring.mass = 1
    spring.initialVelocity = Double(springVelocity) * 8
    spring.duration = spring.settlingDuration
    spring.fillMode = .forwards
    spring.isRemovedOnCompletion = true
    mask.add(spring, forKey: "fk_scale")
    mask.transform = target
  }

  private func progressBorderPath(
    track: CGRect,
    configuration: FKProgressBarConfiguration,
    progress: CGFloat,
    buffer: CGFloat,
    layoutDirection: UIUserInterfaceLayoutDirection,
    corner: CGFloat
  ) -> CGPath? {
    guard configuration.appearance.progressBorderWidth > 0 else { return nil }
    let frame = FKProgressBarLayoutEngine.linearProgressFrameLocal(
      track: track,
      fraction: progress,
      axis: configuration.layout.axis,
      layoutDirection: layoutDirection
    )
    let r = configuration.layout.linearCapStyle == .round ? min(corner, min(frame.width, frame.height) / 2) : 0
    return UIBezierPath(roundedRect: frame, cornerRadius: r).cgPath
  }

  private func layoutRing(
    in trackRect: CGRect,
    configuration: FKProgressBarConfiguration,
    progress: CGFloat,
    buffer: CGFloat,
    isIndeterminate: Bool,
    reducedMotion: Bool,
    disableActions: Bool,
    traitCollection: UITraitCollection
  ) {
    trackLayer.isHidden = true
    bufferHost.isHidden = true
    progressHost.isHidden = true
    progressBorder.isHidden = true
    marqueeCapsule.isHidden = true

    // Ring paths are authored in **track-local** space; layer frames match `trackRect` so centers stay aligned with the linear track inset.
    ringBuffer.frame = trackRect
    ringTrack.frame = trackRect
    ringProgress.frame = trackRect
    ringMarquee.frame = trackRect

    ringBuffer.isHidden = !configuration.appearance.showsBuffer
    ringTrack.isHidden = false
    ringProgress.isHidden = false
    ringTrack.opacity = 1
    ringBuffer.opacity = 1
    ringProgress.opacity = 1
    ringMarquee.opacity = 1

    let diameter = configuration.layout.ringDiameter ?? 36
    let localTrack = CGRect(origin: .zero, size: trackRect.size)
    let side = min(min(localTrack.width, localTrack.height), diameter)
    let ringBox = CGRect(
      x: localTrack.midX - side / 2,
      y: localTrack.midY - side / 2,
      width: side,
      height: side
    )
    let lw = configuration.layout.ringLineWidth
    let layout = FKProgressBarLayoutEngine.ringLayout(in: ringBox, lineWidth: lw)
    let path = FKProgressBarLayoutEngine.ringPath(center: layout.center, radius: layout.radius)

    ringTrack.path = path
    ringTrack.strokeColor = configuration.appearance.trackColor.cgColor
    ringTrack.lineWidth = lw
    ringTrack.strokeEnd = 1
    let baseRot = CATransform3DMakeRotation(FKProgressBarLayoutEngine.ringStartAngle(), 0, 0, 1)
    ringTrack.transform = baseRot
    ringBuffer.transform = baseRot
    ringProgress.transform = baseRot
    ringMarquee.transform = baseRot

    ringBuffer.path = path
    ringBuffer.strokeColor = configuration.appearance.bufferColor.cgColor
    ringBuffer.lineWidth = lw
    ringBuffer.strokeEnd = min(max(buffer, 0), 1)

    ringProgress.path = path
    ringProgress.strokeColor = resolvedRingProgressColor(configuration: configuration, traitCollection: traitCollection)
    ringProgress.lineWidth = lw
    ringProgress.strokeEnd = min(max(progress, 0), 1)

    ringMarquee.path = path
    ringMarquee.strokeColor = configuration.appearance.progressColor.cgColor
    ringMarquee.lineWidth = lw
    ringMarquee.strokeStart = 0
    ringMarquee.strokeEnd = 0.22
    ringMarquee.fillColor = UIColor.clear.cgColor

    let effectiveReduced = reducedMotion && configuration.motion.respectsReducedMotion
    let indeterminateState = isIndeterminate && configuration.motion.indeterminateStyle != .none
    let playsIndeterminateMotion = configuration.motion.playsIndeterminateAnimation

    animator.stopAll()
    if indeterminateState, configuration.motion.indeterminateStyle == .marquee, playsIndeterminateMotion, !effectiveReduced {
      ringMarquee.isHidden = false
      ringProgress.opacity = 0.15
      animator.startMarqueeRing(period: configuration.motion.indeterminatePeriod, reducedMotion: effectiveReduced)
    } else if indeterminateState, configuration.motion.indeterminateStyle == .breathing, playsIndeterminateMotion {
      ringMarquee.isHidden = true
      ringProgress.opacity = 1
      animator.startBreathing(layers: [ringTrack, ringProgress], period: configuration.motion.indeterminatePeriod, reducedMotion: effectiveReduced)
    } else {
      ringMarquee.isHidden = true
      ringProgress.opacity = 1
    }
  }

  private func resolvedRingProgressColor(configuration: FKProgressBarConfiguration, traitCollection: UITraitCollection) -> CGColor {
    switch configuration.appearance.fillStyle {
    case .solid:
      return configuration.appearance.progressColor.cgColor
    case .gradientAlongProgress:
      // True conic gradients are not modeled here; blend endpoints by midpoint for a stable ring stroke.
      let blended = averageColor(configuration.appearance.progressColor, configuration.appearance.progressGradientEndColor, traitCollection: traitCollection)
      return blended.cgColor
    }
  }

  private func averageColor(_ a: UIColor, _ b: UIColor, traitCollection: UITraitCollection) -> UIColor {
    let ta = a.resolvedColor(with: traitCollection)
    let tb = b.resolvedColor(with: traitCollection)
    var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
    var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
    guard ta.getRed(&ar, green: &ag, blue: &ab, alpha: &aa),
          tb.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
    else {
      return a
    }
    return UIColor(red: (ar + br) / 2, green: (ag + bg) / 2, blue: (ab + bb) / 2, alpha: (aa + ba) / 2)
  }

  private func resolvedCornerRadius(configuration: FKProgressBarConfiguration, track: CGRect) -> CGFloat {
    if let r = configuration.layout.trackCornerRadius { return max(0, r) }
    return min(configuration.layout.trackThickness, min(track.width, track.height)) / 2
  }

  private func applyGradient(configuration: FKProgressBarConfiguration, layoutDirection: UIUserInterfaceLayoutDirection, in size: CGSize) {
    switch configuration.appearance.fillStyle {
    case .solid:
      progressGradient.colors = [
        configuration.appearance.progressColor.cgColor,
        configuration.appearance.progressColor.cgColor,
      ]
    case .gradientAlongProgress:
      progressGradient.colors = [
        configuration.appearance.progressColor.cgColor,
        configuration.appearance.progressGradientEndColor.cgColor,
      ]
    }
    let isRTL = layoutDirection == .rightToLeft
    progressGradient.startPoint = CGPoint(x: isRTL ? 1 : 0, y: 0.5)
    progressGradient.endPoint = CGPoint(x: isRTL ? 0 : 1, y: 0.5)
    switch configuration.layout.axis {
    case .horizontal:
      break
    case .vertical:
      progressGradient.startPoint = CGPoint(x: 0.5, y: 1)
      progressGradient.endPoint = CGPoint(x: 0.5, y: 0)
    }
  }
}
