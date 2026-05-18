import UIKit

/// Reuses a bounded number of ``FKVideoPlayer`` instances for feed scrolling.
@MainActor
public final class FKVideoPlayerPool {

  public let maxPlayers: Int
  private var available: [FKVideoPlayer] = []
  private var inUse: [ObjectIdentifier: FKVideoPlayer] = [:]

  public init(maxPlayers: Int = 3, configuration: FKVideoPlayerConfiguration = .shared) {
    self.maxPlayers = max(1, maxPlayers)
    self.configuration = configuration
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMemoryWarningNotification),
      name: UIApplication.didReceiveMemoryWarningNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private let configuration: FKVideoPlayerConfiguration

  public func player(for host: AnyObject) -> FKVideoPlayer {
    let key = ObjectIdentifier(host)
    if let existing = inUse[key] {
      return existing
    }
    let player: FKVideoPlayer
    if let reused = available.popLast() {
      player = reused
    } else if inUse.count < maxPlayers {
      player = FKVideoPlayer(configuration: configuration)
    } else if let evictedKey = inUse.keys.first, let evicted = inUse.removeValue(forKey: evictedKey) {
      // Pool is at capacity: recycle an in-use player (host must call `releasePlayer` when off-screen).
      evicted.stop()
      player = evicted
    } else {
      player = FKVideoPlayer(configuration: configuration)
    }
    inUse[key] = player
    return player
  }

  public func releasePlayer(for host: AnyObject, keepAlive: Bool = false) {
    let key = ObjectIdentifier(host)
    guard let player = inUse.removeValue(forKey: key) else { return }
    player.pause()
    if keepAlive, available.count < maxPlayers {
      available.append(player)
    } else {
      player.stop()
    }
  }

  public func drainAll() {
    for player in inUse.values {
      player.stop()
    }
    inUse.removeAll()
    available.removeAll()
  }

  public func handleMemoryWarning() {
    for player in available {
      player.stop()
    }
    available.removeAll()
  }

  /// Applies a lower peak bitrate when Low Power Mode is enabled.
  public func applyLowPowerPolicyIfNeeded(to player: FKVideoPlayer) {
    guard ProcessInfo.processInfo.isLowPowerModeEnabled else { return }
    player.selectPeakBitrate(800_000)
  }

  @objc
  private func handleMemoryWarningNotification() {
    handleMemoryWarning()
  }
}
