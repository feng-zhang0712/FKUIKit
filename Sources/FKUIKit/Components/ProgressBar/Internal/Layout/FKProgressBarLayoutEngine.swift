import UIKit

/// Pure geometry for track, fills, and ring paths (no UIKit view hierarchy).
enum FKProgressBarLayoutEngine {
  // MARK: - Track rect

  static func trackRect(in bounds: CGRect, contentInsets: UIEdgeInsets) -> CGRect {
    bounds.inset(by: contentInsets)
  }

  // MARK: - Linear fill fraction → frame

  static func linearProgressFrame(
    track: CGRect,
    fraction: CGFloat,
    axis: FKProgressBarAxis,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGRect {
    let t = min(max(fraction, 0), 1)
    switch axis {
    case .horizontal:
      let w = track.width * t
      if layoutDirection == .rightToLeft {
        return CGRect(x: track.maxX - w, y: track.minY, width: w, height: track.height)
      }
      return CGRect(x: track.minX, y: track.minY, width: w, height: track.height)
    case .vertical:
      let h = track.height * t
      return CGRect(x: track.minX, y: track.maxY - h, width: track.width, height: h)
    }
  }

  // MARK: - Ring

  static func ringLayout(in rect: CGRect, lineWidth: CGFloat) -> (center: CGPoint, radius: CGFloat) {
    let inset = lineWidth / 2
    let r = min(rect.width, rect.height) / 2 - inset
    let c = CGPoint(x: rect.midX, y: rect.midY)
    return (c, max(1, r))
  }

  static func ringPath(center: CGPoint, radius: CGFloat) -> CGPath {
    let b = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    return UIBezierPath(ovalIn: b).cgPath
  }

  /// Start at 12 o'clock, clockwise (standard “download ring”).
  static func ringStartAngle() -> CGFloat { -.pi / 2 }

  // MARK: - Segmented paths

  static func segmentParameters(track: CGRect, segmentCount: Int, gapFraction: CGFloat, axis: FKProgressBarAxis) -> (cellCount: Int, cellSpan: CGFloat, gap: CGFloat)? {
    guard segmentCount > 1 else { return nil }
    let n = segmentCount
    let g = min(max(gapFraction, 0), 0.45)
    switch axis {
    case .horizontal:
      let denom = CGFloat(n) + CGFloat(max(0, n - 1)) * g
      let cellW = track.width / max(denom, 0.001)
      let gap = g * cellW
      if cellW <= 0.5 { return nil }
      return (n, cellW, gap)
    case .vertical:
      let denom = CGFloat(n) + CGFloat(max(0, n - 1)) * g
      let cellH = track.height / max(denom, 0.001)
      let gap = g * cellH
      if cellH <= 0.5 { return nil }
      return (n, cellH, gap)
    }
  }

  static func filledSegmentIndex(progress: CGFloat, segmentCount: Int) -> Int {
    guard segmentCount > 0 else { return 0 }
    let t = min(max(progress, 0), 1)
    return min(segmentCount, Int((t * CGFloat(segmentCount)).rounded(.down)))
  }

  /// Segment union path in **track-local** coordinates (origin at the track’s top-leading corner).
  /// Use this for masks and fills hosted in a layer whose `frame` equals `track` in the container.
  static func linearSegmentUnionPath(
    track: CGRect,
    configuration: FKProgressBarConfiguration,
    filledSegments: Int,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGPath? {
    let n = configuration.layout.segmentCount
    guard n > 1, let params = segmentParameters(track: track, segmentCount: n, gapFraction: configuration.layout.segmentGapFraction, axis: configuration.layout.axis) else {
      return nil
    }
    let path = UIBezierPath()
    let cellCount = params.cellCount
    let span = params.cellSpan
    let gap = params.gap
    let isRTL = configuration.layout.axis == .horizontal && layoutDirection == .rightToLeft
    let th = track.height
    let tw = track.width
    for i in 0 ..< min(filledSegments, cellCount) {
      let rect: CGRect
      switch configuration.layout.axis {
      case .horizontal:
        let logicalIndex = isRTL ? (cellCount - 1 - i) : i
        let x = CGFloat(logicalIndex) * (span + gap)
        rect = CGRect(x: x, y: 0, width: span, height: th)
      case .vertical:
        let y = th - CGFloat(i + 1) * span - CGFloat(i) * gap
        rect = CGRect(x: 0, y: y, width: tw, height: span)
      }
      let r = configuration.layout.trackCornerRadius ?? min(rect.width, rect.height) / 2
      path.append(UIBezierPath(roundedRect: rect, cornerRadius: r))
    }
    return path.cgPath
  }

  static func linearTrackSegmentedPath(track: CGRect, configuration: FKProgressBarConfiguration, layoutDirection: UIUserInterfaceLayoutDirection) -> CGPath? {
    linearSegmentUnionPath(track: track, configuration: configuration, filledSegments: configuration.layout.segmentCount, layoutDirection: layoutDirection)
  }

  /// Single continuous rounded-rect path for the full track (non-segmented), in **track-local** coordinates.
  static func linearContinuousRoundedPath(in track: CGRect, cornerRadius: CGFloat) -> CGPath {
    UIBezierPath(roundedRect: CGRect(origin: .zero, size: track.size), cornerRadius: cornerRadius).cgPath
  }

  /// Progress fill frame in **track-local** coordinates (for borders / clipping hosted in `frame: track`).
  static func linearProgressFrameLocal(
    track: CGRect,
    fraction: CGFloat,
    axis: FKProgressBarAxis,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGRect {
    let abs = linearProgressFrame(track: track, fraction: fraction, axis: axis, layoutDirection: layoutDirection)
    return abs.offsetBy(dx: -track.minX, dy: -track.minY)
  }
}
