import Foundation

// MARK: - Main-thread assertion

/// Ensures empty-state APIs run on the main queue. Crashes in debug if violated.
///
/// Why crash instead of silently dispatching to main?
/// - UI code often expects synchronous state (e.g. a model is stored, then immediately read).
/// - For open-source modules, failing fast makes integration mistakes obvious during development.
func fk_emptyStateAssertMainThread(file: StaticString = #fileID, line: UInt = #line) {
  dispatchPrecondition(condition: .onQueue(.main))
}
