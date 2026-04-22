import UIKit

/// Runtime configuration for sticky calculation.
public struct FKStickyConfiguration: @unchecked Sendable {
  /// Sticky animation timing curve.
  public enum AnimationCurve {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case custom((_ progress: CGFloat) -> CGFloat)

    @inlinable
    func value(for progress: CGFloat) -> CGFloat {
      let clamped = max(0, min(progress, 1))
      switch self {
      case .linear:
        return clamped
      case .easeIn:
        return clamped * clamped
      case .easeOut:
        return 1 - ((1 - clamped) * (1 - clamped))
      case .easeInOut:
        if clamped < 0.5 {
          return 2 * clamped * clamped
        }
        return 1 - pow(-2 * clamped + 2, 2) / 2
      case let .custom(curve):
        return max(0, min(curve(clamped), 1))
      }
    }
  }

  /// Additional top offset added to safe-area inset.
  public var additionalTopInset: CGFloat

  /// Whether to include `adjustedContentInset.top` when pinning.
  public var usesAdjustedContentInset: Bool

  /// Enable automatic safe-area adaptation.
  public var adaptsSafeArea: Bool

  /// Extra sticky reference offset in viewport coordinates.
  ///
  /// Use this value when your pinned header must stay below a custom top bar.
  public var referenceOffsetY: CGFloat

  /// Distance used for sticky transition progress calculation.
  public var transitionDistance: CGFloat

  /// Transition curve used by progress callbacks.
  public var animationCurve: AnimationCurve

  /// Enables sticky processing.
  public var isEnabled: Bool

  /// Emits every scroll callback.
  public var onDidScroll: ((_ scrollView: UIScrollView, _ effectiveOffsetY: CGFloat) -> Void)?

  /// Creates a configuration object.
  public init(
    additionalTopInset: CGFloat = 0,
    usesAdjustedContentInset: Bool = true,
    adaptsSafeArea: Bool = true,
    referenceOffsetY: CGFloat = 0,
    transitionDistance: CGFloat = 28,
    animationCurve: AnimationCurve = .easeOut,
    isEnabled: Bool = true,
    onDidScroll: ((_ scrollView: UIScrollView, _ effectiveOffsetY: CGFloat) -> Void)? = nil
  ) {
    self.additionalTopInset = additionalTopInset
    self.usesAdjustedContentInset = usesAdjustedContentInset
    self.adaptsSafeArea = adaptsSafeArea
    self.referenceOffsetY = referenceOffsetY
    self.transitionDistance = max(1, transitionDistance)
    self.animationCurve = animationCurve
    self.isEnabled = isEnabled
    self.onDidScroll = onDidScroll
  }

  /// Default production configuration.
  public static let `default` = FKStickyConfiguration()
}
