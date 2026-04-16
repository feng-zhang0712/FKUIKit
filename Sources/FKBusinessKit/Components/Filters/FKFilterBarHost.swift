import UIKit

/// Installs ``FKFilterBarPresentation`` under a chosen top anchor and exposes a ``contentLayoutGuide``
/// so main content (table, collection, or plain views) can pin below the bar without subclassing `UIViewController`.
///
/// For atypical hierarchies, use ``install(in:topAnchor:leadingAnchor:trailingAnchor:options:)`` with a custom
/// container and anchors; safe-area and rotation updates are handled by Auto Layout when you use layout guides.
@MainActor
public final class FKFilterBarHost {

  public let filterBar: FKFilterBarPresentation

  /// 1pt separator under the bar when ``InstallOptions/showsBottomHairline`` is true.
  public private(set) var hairlineView: UIView?

  /// Area below the bar (and hairline): top = bottom of bar stack, bottom = chosen bottom anchor (default safe area).
  public let contentLayoutGuide = UILayoutGuide()

  private weak var containerView: UIView?
  private var hostConstraints: [NSLayoutConstraint] = []

  public struct InstallOptions {
    public var barHeight: CGFloat = 50
    public var showsBottomHairline: Bool = true
    /// Bottom edge for ``contentLayoutGuide``. Default pins to the container’s safe area bottom.
    public var contentAreaBottomAnchor: @MainActor (UIView) -> NSLayoutYAxisAnchor = { $0.safeAreaLayoutGuide.bottomAnchor }
    public init() {}
  }

  public init(filterBar: FKFilterBarPresentation = FKFilterBarPresentation()) {
    self.filterBar = filterBar
  }

  /// Typical full-screen VC: bar under the navigation bar (safe area top), full width, optional hairline.
  public func installBelowTopSafeArea(of viewController: UIViewController, options: InstallOptions = InstallOptions()) {
    guard let view = viewController.view else { return }
    install(
      in: view,
      topAnchor: view.safeAreaLayoutGuide.topAnchor,
      leadingAnchor: view.leadingAnchor,
      trailingAnchor: view.trailingAnchor,
      options: options
    )
  }

  /// Full control over container and horizontal anchors (e.g. bar inside a nested card view).
  public func install(
    in container: UIView,
    topAnchor: NSLayoutYAxisAnchor,
    leadingAnchor: NSLayoutXAxisAnchor? = nil,
    trailingAnchor: NSLayoutXAxisAnchor? = nil,
    options: InstallOptions = InstallOptions()
  ) {
    let leading = leadingAnchor ?? container.leadingAnchor
    let trailing = trailingAnchor ?? container.trailingAnchor

    uninstall()

    container.addLayoutGuide(contentLayoutGuide)
    containerView = container

    filterBar.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(filterBar)

    var constraints: [NSLayoutConstraint] = [
      filterBar.topAnchor.constraint(equalTo: topAnchor),
      filterBar.leadingAnchor.constraint(equalTo: leading),
      filterBar.trailingAnchor.constraint(equalTo: trailing),
      filterBar.heightAnchor.constraint(equalToConstant: options.barHeight),
    ]

    let barStackBottom: NSLayoutYAxisAnchor
    if options.showsBottomHairline {
      let hairline = UIView()
      hairline.backgroundColor = UIColor.separator
      hairline.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(hairline)
      hairlineView = hairline
      let scale = container.window?.windowScene?.screen.scale ?? container.traitCollection.displayScale
      let pixel = 1 / max(scale, 1)
      constraints += [
        hairline.topAnchor.constraint(equalTo: filterBar.bottomAnchor),
        hairline.leadingAnchor.constraint(equalTo: leading),
        hairline.trailingAnchor.constraint(equalTo: trailing),
        hairline.heightAnchor.constraint(equalToConstant: pixel),
      ]
      barStackBottom = hairline.bottomAnchor
    } else {
      hairlineView = nil
      barStackBottom = filterBar.bottomAnchor
    }

    let contentBottom = options.contentAreaBottomAnchor(container)
    constraints += [
      contentLayoutGuide.topAnchor.constraint(equalTo: barStackBottom),
      contentLayoutGuide.leadingAnchor.constraint(equalTo: leading),
      contentLayoutGuide.trailingAnchor.constraint(equalTo: trailing),
      contentLayoutGuide.bottomAnchor.constraint(equalTo: contentBottom),
    ]

    NSLayoutConstraint.activate(constraints)
    hostConstraints = constraints
    containerView = container
  }

  /// Removes bar, hairline, and layout guide from the current container.
  public func uninstall() {
    NSLayoutConstraint.deactivate(hostConstraints)
    hostConstraints.removeAll()

    hairlineView?.removeFromSuperview()
    hairlineView = nil

    filterBar.removeFromSuperview()

    if let container = contentLayoutGuide.owningView {
      container.removeLayoutGuide(contentLayoutGuide)
    }
    containerView = nil
  }
}
