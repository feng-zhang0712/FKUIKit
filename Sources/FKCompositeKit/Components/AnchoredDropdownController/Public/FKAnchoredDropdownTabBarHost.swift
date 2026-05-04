import UIKit
import FKUIKit

/// Hosts an ``FKTabBar`` inside a container you control (background, dividers, safe area, etc.).
@MainActor
public protocol FKAnchoredDropdownTabBarHost: AnyObject {
  var view: UIView { get }
  var tabBar: FKTabBar { get }
}

/// Default host: the tab bar fills the bounds of this view.
@MainActor
public final class FKAnchoredDropdownDefaultTabBarHost: UIView, FKAnchoredDropdownTabBarHost {
  public let tabBar: FKTabBar = {
    let bar = FKTabBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var view: UIView { self }

  private func commonInit() {
    addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.topAnchor.constraint(equalTo: topAnchor),
      tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
