import Foundation
import UIKit

/// Default implementation of ``FKBusinessVersioning``.
public final class FKBusinessVersionManager: FKBusinessVersioning, @unchecked Sendable {
  /// Source of app/device metadata used for version comparison.
  private let infoProvider: FKBusinessInfoProviding

  /// Creates a version manager.
  ///
  /// - Parameter infoProvider: App metadata provider.
  public init(infoProvider: FKBusinessInfoProviding) {
    self.infoProvider = infoProvider
  }

  /// Returns local app metadata built from the current runtime info provider.
  public func appMetadata() -> FKAppMetadata {
    FKAppMetadata(bundleID: infoProvider.bundleID, version: infoProvider.appVersion, build: infoProvider.buildNumber)
  }

  /// Checks remote version information and computes update decision.
  ///
  /// - Parameter provider: Remote version provider.
  /// - Returns: Version check result with decision.
  /// - Throws: ``FKBusinessError`` when remote fetch fails.
  @available(iOS 13.0, *)
  public func checkForUpdate(using provider: FKRemoteVersionProviding) async throws -> FKVersionCheckResult {
    let local = appMetadata()
    let remote: FKRemoteVersionInfo
    do {
      remote = try await provider.fetchRemoteVersion()
    } catch {
      throw FKBusinessError.networkFailed(underlying: error.localizedDescription)
    }

    let decision = Self.decide(local: local, remote: remote)
    return FKVersionCheckResult(local: local, remote: remote, decision: decision)
  }

  /// Closure-style wrapper for remote version check.
  ///
  /// - Parameters:
  ///   - provider: Remote version provider.
  ///   - completion: Callback with check result or business error.
  public func checkForUpdate(
    using provider: FKRemoteVersionProviding,
    completion: @escaping @Sendable (Result<FKVersionCheckResult, FKBusinessError>) -> Void
  ) {
    if #available(iOS 13.0, *) {
      Task(priority: .utility) {
        do {
          let result = try await self.checkForUpdate(using: provider)
          completion(.success(result))
        } catch let business as FKBusinessError {
          completion(.failure(business))
        } catch {
          completion(.failure(.unknown(error.localizedDescription)))
        }
      }
    } else {
      completion(.failure(.unsupported("Requires iOS 13+.")))
    }
  }

  /// Presents update prompt based on a resolved decision.
  ///
  /// - Parameters:
  ///   - result: Version check result.
  ///   - presenter: Optional presenter view controller.
  public func presentUpdatePromptIfNeeded(result: FKVersionCheckResult, presenter: UIViewController?) {
    guard result.decision != .upToDate else { return }

    let presentBlock = { [weak self] in
      guard let self else { return }
      let vc = presenter ?? FKTopViewControllerResolver.topMostViewController()
      guard let vc else { return }
      let title = "Update Available"
      let message = Self.buildMessage(remote: result.remote)

      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let updateTitle = "Update"
      alert.addAction(UIAlertAction(title: updateTitle, style: .default) { _ in
        if let url = result.remote.updateURL {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        if result.decision == .forceUpdate {
          self.presentUpdatePromptIfNeeded(result: result, presenter: vc)
        }
      })

      if result.decision == .optionalUpdate {
        alert.addAction(UIAlertAction(title: "Later", style: .cancel))
      }

      vc.present(alert, animated: true)
    }

    if Thread.isMainThread {
      presentBlock()
    } else {
      DispatchQueue.main.async(execute: presentBlock)
    }
  }

  /// Builds alert message content from remote metadata.
  ///
  /// - Parameter remote: Remote version information.
  /// - Returns: User-facing alert message.
  private static func buildMessage(remote: FKRemoteVersionInfo) -> String {
    var parts: [String] = []
    parts.append("Latest version: \(remote.version)")
    if let notes = remote.releaseNotes, !notes.isEmpty {
      parts.append(notes)
    }
    if remote.isForceUpdate {
      parts.append("This update is required to continue.")
    }
    return parts.joined(separator: "\n\n")
  }

  /// Resolves update decision from local and remote metadata.
  ///
  /// - Parameters:
  ///   - local: Local app metadata.
  ///   - remote: Remote version metadata.
  /// - Returns: Update decision.
  static func decide(local: FKAppMetadata, remote: FKRemoteVersionInfo) -> FKUpdateDecision {
    if remote.isForceUpdate { return .forceUpdate }
    let compare = compareVersions(local.version, remote.version)
    if compare == .orderedAscending {
      return .optionalUpdate
    }
    return .upToDate
  }

  /// Compares dot-separated semantic versions using numeric segments.
  static func compareVersions(_ a: String, _ b: String) -> ComparisonResult {
    let aSeg = a.split(separator: ".").map { Int($0) ?? 0 }
    let bSeg = b.split(separator: ".").map { Int($0) ?? 0 }
    let count = max(aSeg.count, bSeg.count)
    for i in 0..<count {
      let x = i < aSeg.count ? aSeg[i] : 0
      let y = i < bSeg.count ? bSeg[i] : 0
      if x < y { return .orderedAscending }
      if x > y { return .orderedDescending }
    }
    return .orderedSame
  }
}

