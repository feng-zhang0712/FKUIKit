import Foundation

/// Runtime phase of tab switching.
///
/// `switching` is explicit so callers can debounce expensive side effects while transition is in progress.
public enum FKTabBarSwitchPhase: Equatable {
  /// No in-flight transition.
  case idle
  /// Transition started but not committed.
  case switching
  /// Transition completed and settled on a final index.
  case settled
}

/// Immutable selection snapshot used by the tab state machine.
internal struct FKTabBarSelectionSnapshot: Equatable {
  /// Currently selected index.
  public var selectedIndex: Int
  /// Previously selected index.
  public var previousIndex: Int?
  /// Current switching phase.
  public var phase: FKTabBarSwitchPhase

  public init(selectedIndex: Int, previousIndex: Int? = nil, phase: FKTabBarSwitchPhase = .idle) {
    self.selectedIndex = selectedIndex
    self.previousIndex = previousIndex
    self.phase = phase
  }
}

/// Selection event consumed by the reducer.
internal enum FKTabBarSelectionEvent: Equatable {
  /// User tapped a tab item.
  case userTap(Int)
  /// Host code requested a selection change.
  case programmatic(Int)
  /// Interactive container progress update (e.g. pager drag).
  case gestureProgress(from: Int, to: Int, progress: CGFloat)
  /// Interactive container finished and committed a final index.
  case gestureCommit(Int)
  /// Tab list changed and current index may need clamping.
  case itemsChanged(count: Int)
}

/// Pure reducer that keeps tab selection deterministic under rapid or concurrent inputs.
internal enum FKTabBarSelectionReducer {
  /// Reducer output.
  internal struct Output: Equatable {
    internal enum Change: Equatable {
      case none
      case selected(from: Int?, to: Int)
      case reselected(Int)
      case progress(from: Int, to: Int, progress: CGFloat)
    }

    internal var snapshot: FKTabBarSelectionSnapshot
    internal var change: Change

    internal init(snapshot: FKTabBarSelectionSnapshot, change: Change) {
      self.snapshot = snapshot
      self.change = change
    }
  }

  /// Applies an event and returns normalized state.
  ///
  /// - Parameters:
  ///   - snapshot: Current snapshot.
  ///   - event: Incoming event.
  ///   - count: Current tab count.
  /// - Returns: New snapshot and semantic change.
  internal static func reduce(
    snapshot: FKTabBarSelectionSnapshot,
    event: FKTabBarSelectionEvent,
    count: Int
  ) -> Output {
    guard count > 0 else {
      var next = snapshot
      next.previousIndex = snapshot.selectedIndex
      next.selectedIndex = 0
      next.phase = .idle
      return Output(snapshot: next, change: .none)
    }

    func clamp(_ index: Int) -> Int { max(0, min(index, count - 1)) }

    switch event {
    case .itemsChanged:
      let nextIndex = clamp(snapshot.selectedIndex)
      guard nextIndex != snapshot.selectedIndex else {
        return Output(snapshot: snapshot, change: .none)
      }
      var next = snapshot
      next.previousIndex = snapshot.selectedIndex
      next.selectedIndex = nextIndex
      next.phase = .settled
      return Output(snapshot: next, change: .selected(from: snapshot.selectedIndex, to: nextIndex))

    case .userTap(let index), .programmatic(let index), .gestureCommit(let index):
      let target = clamp(index)
      if target == snapshot.selectedIndex {
        return Output(snapshot: snapshot, change: .reselected(target))
      }
      var next = snapshot
      next.previousIndex = snapshot.selectedIndex
      next.selectedIndex = target
      next.phase = .settled
      return Output(snapshot: next, change: .selected(from: snapshot.selectedIndex, to: target))

    case .gestureProgress(let from, let to, let progress):
      let safeFrom = clamp(from)
      let safeTo = clamp(to)
      var next = snapshot
      next.phase = .switching
      return Output(
        snapshot: next,
        change: .progress(from: safeFrom, to: safeTo, progress: max(0, min(progress, 1)))
      )
    }
  }
}

