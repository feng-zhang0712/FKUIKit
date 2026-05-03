import UIKit

extension FKButton {
  open override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    flushPendingRefresh()
  }
}
