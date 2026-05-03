import UIKit
import FKUIKit

/// Single auto-direction anchor popup example.
final class AnchorAutoDirectionExampleViewController: AnchorSingleExampleBaseViewController {
  override var spec: AnchorDemoSpec {
    .init(
      pageTitle: "Auto Direction Anchor",
      anchorTitle: "Tap auto-direction anchor to present",
      popupContentText: "Auto-direction anchor popup content",
      placement: .bottom,
      edge: .top,
      direction: .auto,
      helperText: "Anchor is near bottom; auto direction usually picks upward expansion."
    )
  }
}
