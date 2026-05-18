import UIKit

/// Default ``FKVideoAdPlugin`` that presents a simple interstitial placeholder.
@MainActor
public final class FKVideoAdCoordinator: FKVideoAdPlugin {

  public var adDurationSeconds: TimeInterval = 5

  private var hostViewController: UIViewController?
  private var overlay: UIView?

  public init() {}

  public func prepareAdBreak(kind: FKVideoAdBreakKind, for item: FKVideoItem) async throws {
    _ = kind
    _ = item
  }

  public func playAdBreak(from viewController: UIViewController?) async {
    guard let viewController else { return }
    hostViewController = viewController

    let container = UIView(frame: viewController.view.bounds)
    container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
    container.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let label = UILabel()
    label.text = "Advertisement"
    label.textColor = .white
    label.font = .systemFont(ofSize: 18, weight: .semibold)
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])

    viewController.view.addSubview(container)
    overlay = container

    try? await Task.sleep(nanoseconds: UInt64(adDurationSeconds * 1_000_000_000))
    teardownAdBreak()
  }

  public func teardownAdBreak() {
    overlay?.removeFromSuperview()
    overlay = nil
    hostViewController = nil
  }
}
