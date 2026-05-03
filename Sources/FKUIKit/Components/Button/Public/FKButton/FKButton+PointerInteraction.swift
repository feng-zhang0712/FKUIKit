import UIKit


@available(iOS 13.4, *)
extension FKButton: UIPointerInteractionDelegate {
  public func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion?) -> UIPointerRegion? {
    UIPointerRegion(rect: bounds)
  }

  public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
    let preview = UITargetedPreview(view: self)
    return UIPointerStyle(effect: .highlight(preview), shape: nil)
  }

  public func pointerInteraction(_ interaction: UIPointerInteraction, willEnter region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
    animator.addAnimations { self.isPointerHovered = true }
  }

  public func pointerInteraction(_ interaction: UIPointerInteraction, willExit region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
    animator.addAnimations { self.isPointerHovered = false }
  }
}
