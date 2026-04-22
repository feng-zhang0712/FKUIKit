import UIKit

/// Configuration model for FKSwipeAction.
///
/// This type is **value-based** and can be created on any thread.
/// Actual UI updates are always performed on the main thread by the manager.
///
/// `FKSwipeActionConfiguration` is typically created per row (via provider) to supply
/// left/right action buttons and interaction behavior.
///
/// - Important: The component is designed for iOS 13.0+ and works with UIKit lists
///   (`UITableView` / `UICollectionView`) without requiring cell subclassing.
public struct FKSwipeActionConfiguration: Sendable {
  /// Swipe direction options.
  ///
  /// This option set indicates which swipe directions are allowed for the current list.
  /// Direction meanings follow common iOS conventions:
  /// - `.left`: swipe left to reveal **right** actions.
  /// - `.right`: swipe right to reveal **left** actions.
  public struct Direction: OptionSet, Sendable {
    /// Raw value for the option set.
    public let rawValue: Int
    /// Creates a direction option set from a raw value.
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Reveal actions by swiping left (content moves left, right actions appear).
    public static let left = Direction(rawValue: 1 << 0)
    /// Reveal actions by swiping right (content moves right, left actions appear).
    public static let right = Direction(rawValue: 1 << 1)
    /// Allow both left and right.
    public static let both: Direction = [.left, .right]
  }

  /// High level state callback for business logic.
  ///
  /// Use this event stream to observe swipe lifecycle and action taps.
  /// It is useful for analytics, logging, or coordinating other UI behaviors.
  public enum Event: Sendable {
    /// A cell is about to start swiping.
    case willBeginSwipe(indexPath: IndexPath, direction: Direction)
    /// Swipe ended with final open state.
    case didEndSwipe(indexPath: IndexPath, isOpen: Bool, direction: Direction?)
    /// A button is tapped.
    case didTapAction(indexPath: IndexPath, actionID: String)
  }

  /// Left side actions (revealed when swiping right).
  ///
  /// These buttons are shown behind the cell when the user swipes to the right.
  public var leftActions: [FKSwipeActionButton]
  /// Right side actions (revealed when swiping left).
  ///
  /// These buttons are shown behind the cell when the user swipes to the left.
  public var rightActions: [FKSwipeActionButton]

  /// Allowed swipe directions for this list.
  public var allowedDirections: Direction

  /// Distance threshold (points) required to open actions when finger releases.
  ///
  /// If the user releases the finger after swiping at least this distance,
  /// the component will snap to the fully-open state.
  public var openThreshold: CGFloat

  /// Whether only one cell can stay open at a time.
  ///
  /// When `true`, opening a new cell will automatically close the previously opened one.
  public var allowsOnlyOneOpen: Bool

  /// Whether tapping on cell's non-button area will close the opened actions.
  ///
  /// When `true`, a tap anywhere in the list will close the currently opened cell (if any).
  public var tapToClose: Bool

  /// Whether the cell auto closes after tapping an action.
  public var autoCloseAfterAction: Bool

  /// Whether to apply a subtle rubber-band beyond max reveal width.
  ///
  /// When enabled, swiping beyond the maximum reveal width will have resistance instead of hard clamp.
  public var usesRubberBand: Bool

  /// Animation duration used for snapping open/close.
  public var animationDuration: TimeInterval

  /// Optional event callback.
  ///
  /// - Note: This callback may be invoked frequently during interaction.
  ///   Keep your handler lightweight to preserve 60fps performance.
  public var onEvent: (@Sendable (Event) -> Void)?

  /// Creates a configuration.
  ///
  /// - Parameters:
  ///   - leftActions: Buttons revealed by swiping right.
  ///   - rightActions: Buttons revealed by swiping left.
  ///   - allowedDirections: Allowed swipe directions.
  ///   - openThreshold: Distance threshold (points) to snap open.
  ///   - allowsOnlyOneOpen: Whether only one cell can be open at a time.
  ///   - tapToClose: Whether tapping on the list closes an opened cell.
  ///   - autoCloseAfterAction: Whether to close after tapping an action.
  ///   - usesRubberBand: Whether to apply rubber-band resistance beyond max width.
  ///   - animationDuration: Snap animation duration.
  ///   - onEvent: Optional event callback.
  public init(
    leftActions: [FKSwipeActionButton] = [],
    rightActions: [FKSwipeActionButton] = [],
    allowedDirections: Direction = .both,
    openThreshold: CGFloat = 44,
    allowsOnlyOneOpen: Bool = true,
    tapToClose: Bool = true,
    autoCloseAfterAction: Bool = true,
    usesRubberBand: Bool = true,
    animationDuration: TimeInterval = 0.22,
    onEvent: (@Sendable (Event) -> Void)? = nil
  ) {
    self.leftActions = leftActions
    self.rightActions = rightActions
    self.allowedDirections = allowedDirections
    self.openThreshold = openThreshold
    self.allowsOnlyOneOpen = allowsOnlyOneOpen
    self.tapToClose = tapToClose
    self.autoCloseAfterAction = autoCloseAfterAction
    self.usesRubberBand = usesRubberBand
    self.animationDuration = animationDuration
    self.onEvent = onEvent
  }
}

