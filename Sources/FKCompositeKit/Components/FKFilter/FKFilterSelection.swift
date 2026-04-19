import Foundation

/// Internal helper that computes the effective selection mode.
///
/// The effective mode is the intersection of:
/// - The panel-level gate (e.g. `FKFilterBarPresentation.BarItemModel.allowsMultipleSelection`)
/// - The section-level request (`FKFilterSection.selectionMode`)
///
/// This keeps selection semantics consistent across list/chips/grid panels.
enum FKFilterSelection {
  static func effectiveMode(
    requestedMode: FKFilterSelectionMode,
    allowsMultipleSelection: Bool
  ) -> FKFilterSelectionMode {
    (allowsMultipleSelection && requestedMode == .multiple) ? .multiple : .single
  }
}

