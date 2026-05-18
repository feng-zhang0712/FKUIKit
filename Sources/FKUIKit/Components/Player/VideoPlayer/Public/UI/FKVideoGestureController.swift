import AVFoundation
import MediaPlayer
import UIKit

/// Handles tap, double-tap, and vertical pan gestures on the player surface.
@MainActor
final class FKVideoGestureController: NSObject, UIGestureRecognizerDelegate {

  private weak var hostView: UIView?
  private weak var player: FKVideoPlayer?
  private var uiConfiguration: FKVideoUIConfiguration = .default

  private var controlsVisibilityHandler: ((Bool) -> Void)?
  private var panAxis: PanAxis = .none
  private var panStartPoint: CGPoint = .zero
  private var initialBrightness: CGFloat = 0
  private var initialVolume: Float = 0

  private enum PanAxis {
    case none
    case horizontal
    case verticalLeft
    case verticalRight
  }

  func attach(
    to view: UIView,
    player: FKVideoPlayer,
    configuration: FKVideoUIConfiguration,
    onControlsVisibilityChange: @escaping (Bool) -> Void
  ) {
    hostView = view
    self.player = player
    uiConfiguration = configuration
    controlsVisibilityHandler = onControlsVisibilityChange

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    tap.cancelsTouchesInView = false
    tap.delegate = self
    view.addGestureRecognizer(tap)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTap.numberOfTapsRequired = 2
    view.addGestureRecognizer(doubleTap)
    tap.require(toFail: doubleTap)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.maximumNumberOfTouches = 1
    view.addGestureRecognizer(pan)
  }

  // MARK: - Gestures

  @objc
  private func handleTap() {
    guard let controlView = player?.boundView?.controlView, !controlView.isControlsLocked else { return }
    let visible = controlView.alpha > 0.5
    let willShow = !visible
    controlView.setControlsVisible(willShow, animated: true)
    controlsVisibilityHandler?(willShow)
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let controlView = player?.boundView?.controlView else { return true }
    guard let touchedView = touch.view else { return true }
    return !touchedView.isDescendant(of: controlView)
  }

  @objc
  private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
    guard let player, let view = hostView else { return }
    let location = gesture.location(in: view)
    if location.x < view.bounds.width / 2 {
      let delta = -uiConfiguration.gestureSeekSeconds
      player.seek(to: max(0, player.currentTime + delta), completion: nil)
    } else {
      let delta = uiConfiguration.gestureSeekSeconds
      player.seek(to: player.currentTime + delta, completion: nil)
    }
  }

  @objc
  private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard let view = hostView, let player else { return }
    let point = gesture.location(in: view)

    switch gesture.state {
    case .began:
      panStartPoint = point
      panAxis = .none
      initialBrightness = UIScreen.main.brightness
      initialVolume = AVAudioSession.sharedInstance().outputVolume
    case .changed:
      let dx = point.x - panStartPoint.x
      let dy = point.y - panStartPoint.y
      if panAxis == .none {
        if abs(dx) > abs(dy), abs(dx) > 12 {
          panAxis = .horizontal
        } else if abs(dy) > 12 {
          panAxis = point.x < view.bounds.width / 2 ? .verticalLeft : .verticalRight
        }
      }
      switch panAxis {
      case .horizontal:
        guard !player.isLive, player.duration > 0 else { return }
        let ratio = dx / view.bounds.width
        let target = player.currentTime + Double(ratio) * player.duration
        player.seek(to: min(max(0, target), player.duration), completion: nil)
        panStartPoint = point
      case .verticalLeft:
        let delta = -dy / view.bounds.height
        UIScreen.main.brightness = min(1, max(0, initialBrightness + delta))
      case .verticalRight:
        let delta = -dy / view.bounds.height
        setSystemVolume(initialVolume + Float(delta))
      case .none:
        break
      }
    default:
      panAxis = .none
    }
  }

  private func setSystemVolume(_ value: Float) {
    let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    hostView?.addSubview(volumeView)
    if let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first {
      slider.value = min(1, max(0, value))
    }
    volumeView.removeFromSuperview()
  }

}
