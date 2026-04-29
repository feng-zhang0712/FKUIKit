import UIKit
import FKUIKit

/// Abstraction for hosting an `FKTabBar` inside a customizable container.
///
/// This enables apps to fully customize the "red box" area (background, divider, padding, shadows),
/// while still reusing `FKTabBar` for selection logic and events.
@MainActor
public protocol FKTabDropdownTabBarHosting: AnyObject {
  /// The root view that will be placed in the controller's hierarchy.
  var view: UIView { get }
  /// The underlying tab bar used by the component.
  var tabBar: FKTabBar { get }
}

/// Default tab bar host: the tab bar fills the container.
@MainActor
public final class FKDefaultTabDropdownTabBarHost: UIView, FKTabDropdownTabBarHosting {
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

