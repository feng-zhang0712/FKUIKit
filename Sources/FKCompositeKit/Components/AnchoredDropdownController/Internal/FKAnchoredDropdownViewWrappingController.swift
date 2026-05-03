import UIKit

@MainActor
internal final class FKAnchoredDropdownViewWrappingController: UIViewController {
  private let makeView: () -> UIView

  init(makeView: @escaping () -> UIView) {
    self.makeView = makeView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = makeView()
  }
}
