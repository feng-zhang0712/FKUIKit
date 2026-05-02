import ObjectiveC.runtime
import UIKit

// MARK: - Associated objects

enum FKEmptyStateHostKeys {
  nonisolated(unsafe) static var view: UInt8 = 0
  nonisolated(unsafe) static var configuration: UInt8 = 0
}

/// Box so the last-applied ``FKEmptyStateConfiguration`` can live in associated objects.
final class FKEmptyStateConfigurationBox {
  let configuration: FKEmptyStateConfiguration
  init(_ configuration: FKEmptyStateConfiguration) { self.configuration = configuration }
}

// MARK: - Scroll / refresh helpers

/// Returns `true` when a loading overlay should be suppressed because pull-to-refresh is active.
func fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: UIView, configuration: FKEmptyStateConfiguration) -> Bool {
  guard let scroll = host as? UIScrollView else { return false }
  guard configuration.phase == .loading, configuration.skipsLoadingWhileRefreshing else { return false }
  return scroll.refreshControl?.isRefreshing == true
}

/// Applies ``FKEmptyStateConfiguration/keepScrollEnabled`` when the host is a `UIScrollView`.
func fk_emptyStateApplyScrollInteraction(host: UIView, configuration: FKEmptyStateConfiguration) {
  guard let scroll = host as? UIScrollView else { return }
  scroll.isScrollEnabled = configuration.keepScrollEnabled
}
