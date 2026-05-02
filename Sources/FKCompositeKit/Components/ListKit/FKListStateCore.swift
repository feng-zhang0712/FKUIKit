//
// FKListStateCore.swift
// FKUIKit — List state
//
// Shared types for ``FKListStateManager``: presentation state, content snapshots,
// portable error descriptions, and default mapping into ``FKEmptyStateConfiguration``.
//

import UIKit
import FKUIKit

// MARK: - Loading

/// How a `.loading` state should present (skeleton vs silent reload).
public enum FKListLoadingKind: Equatable {
  /// First paint / full reload: prefer skeleton + hidden list until data resolves.
  case initial
  /// In-place reload: keep the list surface visible, no skeleton curtain.
  case silent
}

// MARK: - Content snapshot (pagination-friendly)

/// Successful list snapshot; ``FKPageManager`` forwards `itemCount` / `hasMorePages` here when bridging list state.
public struct FKListContentSnapshot: Equatable {
  public var itemCount: Int
  /// When `false`, footers should move to a “no more data” idle state after success.
  public var hasMorePages: Bool

  public init(itemCount: Int, hasMorePages: Bool = true) {
    self.itemCount = max(0, itemCount)
    self.hasMorePages = hasMorePages
  }
}

// MARK: - Error taxonomy

/// High-level failure buckets for analytics and default empty-state copy.
public enum FKListErrorProfile: Equatable, Hashable {
  case noNetwork
  case timeout
  case server(code: Int?)
  case business(code: String?, underlyingMessage: String?)
  case cancelled
  case unknown
}

/// Portable error value for ``FKListState``; use ``FKListDisplayedError/resolve(from:)`` for `Error` bridging.
public struct FKListDisplayedError: Equatable {
  public var profile: FKListErrorProfile
  public var title: String?
  public var message: String?
  /// Optional illustration mapped into ``FKEmptyStateConfiguration/image``.
  public var image: UIImage?

  public init(profile: FKListErrorProfile, title: String? = nil, message: String? = nil, image: UIImage? = nil) {
    self.profile = profile
    self.title = title
    self.message = message
    self.image = image
  }

  public static func == (lhs: FKListDisplayedError, rhs: FKListDisplayedError) -> Bool {
    lhs.profile == rhs.profile && lhs.title == rhs.title && lhs.message == rhs.message
  }

  /// Best-effort mapping from any `Error` (URL errors, cancellation, etc.).
  public static func resolve(from error: Error) -> FKListDisplayedError {
    if error is CancellationError {
      return FKListDisplayedError(profile: .cancelled, title: nil, message: nil)
    }
    let ns = error as NSError
    if ns.domain == NSURLErrorDomain {
      switch ns.code {
      case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorDataNotAllowed:
        return FKListDisplayedError(
          profile: .noNetwork,
          title: nil,
          message: ns.localizedDescription
        )
      case NSURLErrorTimedOut:
        return FKListDisplayedError(
          profile: .timeout,
          title: nil,
          message: ns.localizedDescription
        )
      default:
        break
      }
    }
    if let urlError = error as? URLError {
      switch urlError.code {
      case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
        return FKListDisplayedError(profile: .noNetwork, message: urlError.localizedDescription)
      case .timedOut:
        return FKListDisplayedError(profile: .timeout, message: urlError.localizedDescription)
      default:
        break
      }
    }
    return FKListDisplayedError(profile: .unknown, message: error.localizedDescription)
  }

  /// Maps common HTTP status codes into ``FKListErrorProfile/server`` with optional body text.
  public static func http(statusCode: Int, message: String? = nil, image: UIImage? = nil) -> FKListDisplayedError {
    FKListDisplayedError(
      profile: .server(code: statusCode),
      message: message,
      image: image
    )
  }

  /// Convenience for domain-specific failures (already-localised copy recommended).
  public static func business(code: String?, message: String?, image: UIImage? = nil) -> FKListDisplayedError {
    FKListDisplayedError(
      profile: .business(code: code, underlyingMessage: message),
      message: message,
      image: image
    )
  }
}

// MARK: - Default empty-state mapping

public enum FKListEmptyStateConfigurationFactory {
  /// Builds the standard empty overlay (no rows).
  public static func configurationForEmptyList(
    base: FKEmptyStateConfiguration = FKEmptyStateConfiguration(
      phase: .empty,
      title: "Nothing here yet",
      description: "When there’s something to show, it will appear in this list.",
      isButtonHidden: true
    )
  ) -> FKEmptyStateConfiguration {
    var model = base
    model.phase = .empty
    model.keepScrollEnabled = false
    return model
  }

  /// Builds an error overlay with mandatory retry styling (``FKEmptyStatePhase/error``).
  public static func configurationForDisplayedError(
    _ error: FKListDisplayedError,
    base: FKEmptyStateConfiguration = FKEmptyStateConfiguration.scenario(.loadFailed)
  ) -> FKEmptyStateConfiguration {
    var model = base
    model.phase = .error
    model.keepScrollEnabled = false
    switch error.profile {
    case .noNetwork:
      model.title = error.title ?? "No network"
      model.description = error.message ?? "Check your connection and try again."
    case .timeout:
      model.title = error.title ?? "Request timed out"
      model.description = error.message ?? "The server took too long to respond. Try again."
    case .server(let code):
      model.title = error.title ?? "Something went wrong"
      if let code {
        model.description = error.message ?? "Server error (\(code)). Try again in a moment."
      } else {
        model.description = error.message ?? "We couldn’t complete the request. Try again."
      }
    case .business(let code, let underlying):
      model.title = error.title ?? "Couldn’t load"
      if let code {
        model.description = error.message ?? underlying ?? "Business error (\(code))."
      } else {
        model.description = error.message ?? underlying ?? "The request couldn’t be completed."
      }
    case .cancelled:
      model.title = error.title ?? "Cancelled"
      model.description = error.message ?? "The request was cancelled."
    case .unknown:
      model.title = error.title ?? "Couldn’t load"
      model.description = error.message ?? "Something unexpected happened. Try again."
    }
    if model.buttonStyle.title == nil {
      model.buttonStyle.title = FKEmptyStateConfiguration.defaultRetryButtonTitle
    }
    model.isButtonHidden = false
    if let image = error.image {
      model.image = image
    }
    return model
  }
}
