import AVFoundation
import AVKit
import UIKit

/// Embeds the system AirPlay route picker in the player chrome.
@MainActor
public final class FKVideoAirPlayPresenter {

  private var routePicker: AVRoutePickerView?
  private var routeDetector: AVRouteDetector?
  private var routesObserver: NSObjectProtocol?
  private weak var hostView: UIView?

  public func attach(to host: UIView, enabled: Bool) {
    detach()
    guard enabled else { return }

    hostView = host

    let picker = AVRoutePickerView()
    picker.prioritizesVideoDevices = true
    picker.tintColor = .white
    picker.activeTintColor = .systemBlue
    picker.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(picker)
    NSLayoutConstraint.activate([
      picker.widthAnchor.constraint(equalToConstant: 32),
      picker.heightAnchor.constraint(equalToConstant: 32),
      picker.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      picker.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor, constant: 8),
    ])
    routePicker = picker

    let detector = AVRouteDetector()
    detector.isRouteDetectionEnabled = true
    routeDetector = detector
    routesObserver = NotificationCenter.default.addObserver(
      forName: .AVRouteDetectorMultipleRoutesDetectedDidChange,
      object: detector,
      queue: .main
    ) { [weak self] _ in
      self?.refreshVisibility()
    }
    refreshVisibility()
    bringToFront(on: host)
  }

  public func bringToFront(on host: UIView) {
    guard let picker = routePicker else { return }
    host.bringSubviewToFront(picker)
  }

  public func detach() {
    if let routesObserver {
      NotificationCenter.default.removeObserver(routesObserver)
      self.routesObserver = nil
    }
    routeDetector?.isRouteDetectionEnabled = false
    routeDetector = nil
    routePicker?.removeFromSuperview()
    routePicker = nil
    hostView = nil
  }

  // MARK: - Private

  private func refreshVisibility() {
    guard let picker = routePicker else { return }
    let hasRoutes = routeDetector?.multipleRoutesDetected ?? false
    picker.isHidden = !hasRoutes
    picker.isUserInteractionEnabled = hasRoutes
    if hasRoutes, let host = hostView {
      bringToFront(on: host)
    }
  }
}
