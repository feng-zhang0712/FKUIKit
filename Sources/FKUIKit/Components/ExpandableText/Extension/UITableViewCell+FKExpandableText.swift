//
// UITableViewCell+FKExpandableText.swift
//
// Convenience APIs for table-view cell reuse scenarios.
//

import UIKit

public extension UITableViewCell {
  /// Binds a stable model key to an expandable text view for reuse-safe state restoration.
  ///
  /// This helper is designed for `cellForRowAt` configuration and prevents
  /// expand/collapse state mismatch caused by cell reuse.
  ///
  /// - Parameters:
  ///   - expandableText: Target expandable text view.
  ///   - key: Stable identifier from your view model, for example post id.
  ///   - defaultExpanded: Initial state when no cache exists.
  func fk_bindExpandableText(
    _ expandableText: FKExpandableText,
    key: String,
    defaultExpanded: Bool = false
  ) {
    expandableText.stateIdentifier = key
    // Apply default only on first bind when there is no cached state.
    if FKExpandableText.stateCache.state(for: key) == nil {
      expandableText.setExpanded(defaultExpanded, animated: false, notify: false)
    } else if let cached = FKExpandableText.stateCache.state(for: key) {
      // Restore cached state without animation to avoid reuse flicker.
      expandableText.setExpanded(cached == .expanded, animated: false, notify: false)
    }
  }
}
