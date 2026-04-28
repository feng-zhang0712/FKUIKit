import UIKit

/// Delegate hooks for FKPresentationController lifecycle and interactive progress.
@MainActor
public protocol FKPresentationControllerDelegate: AnyObject {
  /// Called before the presentation animation starts.
  func presentationControllerWillPresent(_ controller: FKPresentationController)
  /// Called after the presentation animation finishes.
  func presentationControllerDidPresent(_ controller: FKPresentationController)
  /// Called before the dismissal animation starts.
  func presentationControllerWillDismiss(_ controller: FKPresentationController)
  /// Called after the dismissal animation finishes.
  func presentationControllerDidDismiss(_ controller: FKPresentationController)
  /// Called while interactive dismissal progresses.
  func presentationController(_ controller: FKPresentationController, didUpdateProgress progress: CGFloat)
  /// Called when the active sheet detent changes.
  func presentationController(_ controller: FKPresentationController, didChangeDetent detent: FKPresentationDetent, index: Int)
}

public extension FKPresentationControllerDelegate {
  func presentationControllerWillPresent(_ controller: FKPresentationController) {}
  func presentationControllerDidPresent(_ controller: FKPresentationController) {}
  func presentationControllerWillDismiss(_ controller: FKPresentationController) {}
  func presentationControllerDidDismiss(_ controller: FKPresentationController) {}
  func presentationController(_ controller: FKPresentationController, didUpdateProgress progress: CGFloat) {}
  func presentationController(_ controller: FKPresentationController, didChangeDetent detent: FKPresentationDetent, index: Int) {}
}

/// Closure-based lifecycle callbacks for teams that prefer lightweight integration.
public struct FKPresentationControllerLifecycleCallbacks {
  /// Called before the presentation animation starts.
  public var willPresent: (@MainActor () -> Void)?
  /// Called after the presentation animation finishes.
  public var didPresent: (@MainActor () -> Void)?
  /// Called before the dismissal animation starts.
  public var willDismiss: (@MainActor () -> Void)?
  /// Called after the dismissal animation finishes.
  public var didDismiss: (@MainActor () -> Void)?
  /// Called while interactive dismissal progresses.
  public var progress: (@MainActor (CGFloat) -> Void)?
  /// Called when the active sheet detent changes.
  public var detentDidChange: (@MainActor (_ detent: FKPresentationDetent, _ index: Int) -> Void)?

  /// Creates an empty callbacks container with optional closures.
  public init(
    willPresent: (@MainActor () -> Void)? = nil,
    didPresent: (@MainActor () -> Void)? = nil,
    willDismiss: (@MainActor () -> Void)? = nil,
    didDismiss: (@MainActor () -> Void)? = nil,
    progress: (@MainActor (CGFloat) -> Void)? = nil,
    detentDidChange: (@MainActor (_ detent: FKPresentationDetent, _ index: Int) -> Void)? = nil
  ) {
    self.willPresent = willPresent
    self.didPresent = didPresent
    self.willDismiss = willDismiss
    self.didDismiss = didDismiss
    self.progress = progress
    self.detentDidChange = detentDidChange
  }
}
