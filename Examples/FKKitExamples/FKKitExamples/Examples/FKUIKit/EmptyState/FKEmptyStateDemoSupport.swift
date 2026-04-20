//
// FKEmptyStateDemoSupport.swift
//
// Shared English display names and SF Symbol names for FKEmptyState sample screens.
//

import FKUIKit
import UIKit

// MARK: - FKEmptyStateScenario (demo)

extension FKEmptyStateScenario {
  /// Human-readable title for list cells and navigation bars.
  var demoDisplayName: String {
    switch self {
    case .noNetwork: return "No network"
    case .noSearchResult: return "No search results"
    case .noFavorites: return "No favorites"
    case .noOrders: return "No orders"
    case .noMessages: return "No messages"
    case .loadFailed: return "Load failed"
    case .noPermission: return "No permission"
    case .notLoggedIn: return "Not logged in"
    }
  }

  /// SF Symbol name for `UIImage(systemName:)` in previews.
  var demoSymbolName: String {
    switch self {
    case .noNetwork: return "wifi.slash"
    case .noSearchResult: return "magnifyingglass"
    case .noFavorites: return "heart.slash"
    case .noOrders: return "cart"
    case .noMessages: return "tray"
    case .loadFailed: return "exclamationmark.triangle"
    case .noPermission: return "lock.slash"
    case .notLoggedIn: return "person.crop.circle.badge.questionmark"
    }
  }
}
