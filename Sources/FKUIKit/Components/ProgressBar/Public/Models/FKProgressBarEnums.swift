import UIKit

// MARK: - Layout & visual variant

/// High-level presentation of the control.
public enum FKProgressBarVariant: Int, Sendable {
  /// Rectangular track with a fill growing along an axis.
  case linear
  /// Circular stroke (ring) with `strokeEnd` mapped to progress.
  case ring
}

/// Growth axis for ``FKProgressBarVariant/linear``; ignored for rings.
public enum FKProgressBarAxis: Int, Sendable {
  case horizontal
  case vertical
}

/// How the leading and trailing ends of the linear fill are drawn.
public enum FKProgressBarLinearCapStyle: Int, Sendable {
  /// Matches the track corner radius (continuous rounded rect).
  case round
  /// Square ends flush with the fill rect edges.
  case square
}

/// Solid fill or a two-stop gradient on the progress segment.
public enum FKProgressBarFillStyle: Int, Sendable {
  case solid
  /// Leading → trailing in semantic coordinates (RTL-aware for linear; clockwise start for ring).
  case gradientAlongProgress
}

/// Visual style while ``FKProgressBar/isIndeterminate`` is `true`.
public enum FKProgressBarIndeterminateStyle: Int, Sendable {
  /// No automatic animation (host may drive progress manually).
  case none
  /// A capsule sliding along the track (linear) or rotating arc segment (ring).
  case marquee
  /// Opacity pulse on the track.
  case breathing
}

// MARK: - Animation & behavior

/// Built-in timing for determinate progress changes.
public enum FKProgressBarTiming: Int, Sendable {
  case `default`
  case linear
  case easeIn
  case easeOut
  case easeInOut

  func mediaTimingFunction() -> CAMediaTimingFunction {
    switch self {
    case .default:
      return CAMediaTimingFunction(name: .default)
    case .linear:
      return CAMediaTimingFunction(name: .linear)
    case .easeIn:
      return CAMediaTimingFunction(name: .easeIn)
    case .easeOut:
      return CAMediaTimingFunction(name: .easeOut)
    case .easeInOut:
      return CAMediaTimingFunction(name: .easeInEaseOut)
    }
  }
}

/// Optional haptic when progress reaches `1` (or `maximum`).
public enum FKProgressBarCompletionHaptic: Int, Sendable {
  case none
  case light
  case medium
  case rigid
}

/// Placement of an optional numeric / custom label relative to the bar.
public enum FKProgressBarLabelPlacement: Int, Sendable {
  case none
  case above
  case below
  case leading
  case trailing
  /// Centered over the track (may clash with thin bars; increase ``FKProgressBarLabelConfiguration/padding`` or track height).
  case centeredOnTrack
}

/// How the optional label formats the primary progress value.
public enum FKProgressBarLabelFormat: Int, Sendable {
  /// Integer percent `0…100` with `%` suffix (respects `NumberFormatter` locale when set).
  case percentInteger
  /// Fractional percent with configurable digits.
  case percentFractional
  /// Raw normalized `0…1` with digits.
  case normalizedValue
  /// Maps normalized `0…1` through ``FKProgressBarLabelConfiguration/logicalMinimum`` and ``FKProgressBarLabelConfiguration/logicalMaximum`` (see ``FKProgressBarLabelConfiguration/numberFormatter``).
  case logicalRangeValue
}

// MARK: - Interaction & value label behavior

/// Whether the control behaves as a read-only indicator or as a tappable button.
public enum FKProgressBarInteractionMode: Int, Sendable {
  /// Non-interactive: touches pass through (``UIView/isUserInteractionEnabled`` is `false`).
  case indicator
  /// Interactive: uses ``UIControl`` tracking and sends ``UIControl/Event/primaryActionTriggered`` and ``UIControl/Event/touchUpInside`` on successful taps.
  case button
}

/// How the visible label text is chosen when ``FKProgressBarLabelConfiguration/placement`` is not ``FKProgressBarLabelPlacement/none``.
public enum FKProgressBarLabelContentMode: Int, Sendable {
  /// Formatted from ``FKProgressBar/progress`` using ``FKProgressBarLabelConfiguration/format``.
  case formattedProgress
  /// Always shows ``FKProgressBarLabelConfiguration/customTitle`` (progress is visible only in the fill).
  case customTitleOnly
  /// Shows ``FKProgressBarLabelConfiguration/customTitle`` while determinate ``progress`` is zero and ``FKProgressBar/isIndeterminate`` is `false`; otherwise shows the formatted progress string.
  case customTitleWhenIdle
  /// Two lines: ``FKProgressBarLabelConfiguration/customTitle`` on the first line and formatted progress on the second (e.g. action title + percent).
  case customTitleWithProgressSubtitle
}

/// Optional haptics for ``FKProgressBarInteractionMode/button``.
public enum FKProgressBarTouchHaptic: Int, Sendable {
  case none
  case lightImpactOnTouchDown
  case selectionChangedOnTouchDown
}
