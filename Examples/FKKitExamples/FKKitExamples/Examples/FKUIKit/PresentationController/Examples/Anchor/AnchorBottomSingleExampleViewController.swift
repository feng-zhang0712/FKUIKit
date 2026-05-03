import UIKit
import FKUIKit

/// Single bottom-anchor popup example.
final class AnchorBottomSingleExampleViewController: AnchorSingleExampleBaseViewController {
  override var spec: AnchorDemoSpec {
    .init(
      pageTitle: "Bottom Anchor",
      anchorTitle: "Tap bottom anchor to present",
      popupContentText: "Bottom anchor popup content",
      placement: .bottom,
      edge: .top,
      direction: .up,
      helperText: nil
    )
  }
}
