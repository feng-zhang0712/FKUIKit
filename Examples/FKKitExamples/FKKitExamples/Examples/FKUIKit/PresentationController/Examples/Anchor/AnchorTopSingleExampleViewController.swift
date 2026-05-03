import UIKit
import FKUIKit

/// Single top-anchor popup example.
final class AnchorTopSingleExampleViewController: AnchorSingleExampleBaseViewController {
  override var spec: AnchorDemoSpec {
    .init(
      pageTitle: "Top Anchor",
      anchorTitle: "Tap top anchor to present",
      popupContentText: "Top anchor popup content",
      placement: .top,
      edge: .bottom,
      direction: .down,
      helperText: nil
    )
  }
}

