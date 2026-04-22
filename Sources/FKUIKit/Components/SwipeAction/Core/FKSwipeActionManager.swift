import ObjectiveC
import UIKit

/// Internal swipe-action manager bound to a specific scroll view.
///
/// The manager attaches a horizontal pan gesture and drives per-cell transforms without requiring
/// any subclassing of `UITableView`/`UICollectionView` or their cells.
///
/// - Important: This type is part of the FKSwipeAction implementation details.
///   Most apps should integrate via:
///   - `UITableView.fk_enableSwipeActions(configuration:provider:)`
///   - `UICollectionView.fk_enableSwipeActions(configuration:provider:)`
public final class FKSwipeActionManager: NSObject {
  /// Global default configuration template.
  ///
  /// Lists enabled without explicitly passing a configuration will start from this template.
  ///
  /// - Note: Thread-safe. Internally protected by a lock.
  ///
  /// ## Example
  /// ```swift
  /// FKSwipeActionManager.globalDefaultConfiguration = FKSwipeActionConfiguration(
  ///   openThreshold: 48,
  ///   allowsOnlyOneOpen: true
  /// )
  /// ```
  public static var globalDefaultConfiguration: FKSwipeActionConfiguration {
    get { FKSwipeActionGlobalDefaults.shared.configuration }
    set { FKSwipeActionGlobalDefaults.shared.configuration = newValue }
  }

  // Bound list instance (`UITableView` or `UICollectionView`).
  weak var scrollView: UIScrollView?
  // Current effective configuration used during interaction.
  var configuration: FKSwipeActionConfiguration
  // Per-indexPath configuration provider (installed by list extensions).
  private var provider: ((IndexPath) -> FKSwipeActionConfiguration)?

  // Currently opened cell view (if any).
  weak var openedCell: UIView?
  // IndexPath of the opened cell (if any).
  var openedIndexPath: IndexPath?
  // Direction that opened the cell (if any).
  var openedDirection: FKSwipeActionConfiguration.Direction?
  // Dynamic enable flag.
  var isEnabled = true

  // Horizontal pan recognizer to drive swipe.
  var pan: UIPanGestureRecognizer?
  // Tap recognizer used to close an opened cell.
  var tap: UITapGestureRecognizer?
  // Translation baseline used when a new gesture begins.
  private var initialTranslationX: CGFloat = 0

  // Creates a manager bound to the given scroll view.
  init(scrollView: UIScrollView, configuration: FKSwipeActionConfiguration) {
    self.scrollView = scrollView
    self.configuration = configuration
    super.init()
  }

  // Enables/disables FKSwipeAction.
  //
  // - Note: Always executed on main actor because it mutates UI state.
  @MainActor
  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    if !enabled {
      closeOpenedCell(animated: true)
    }
  }

  // Applies a new baseline configuration for this list.
  func apply(configuration: FKSwipeActionConfiguration) {
    self.configuration = configuration
  }

  // Installs the per-indexPath configuration provider.
  func setProvider(_ provider: @escaping (IndexPath) -> FKSwipeActionConfiguration) {
    self.provider = provider
  }

  // Installs gestures on the bound scroll view once.
  @MainActor
  func installIfNeeded() {
    guard pan == nil, let scrollView else { return }

    // Horizontal pan (cancelsTouchesInView = false) to remain non-invasive.
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    pan.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(pan)
    self.pan = pan

    // Tap-to-close should not steal taps from buttons; we only use it when a cell is open.
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    tap.cancelsTouchesInView = false
    tap.delegate = self
    scrollView.addGestureRecognizer(tap)
    self.tap = tap

    // Close when user starts vertical scrolling.
    scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
  }

  // Closes the currently opened cell (if any).
  @MainActor
  func closeOpenedCell(animated: Bool) {
    guard let cellView = openedCell else { return }
    let indexPath = openedIndexPath
    let direction = openedDirection
    openedCell = nil
    openedIndexPath = nil
    openedDirection = nil
    setCell(cellView, translationX: 0, animated: animated)
    if let indexPath {
      configuration.onEvent?(.didEndSwipe(indexPath: indexPath, isOpen: false, direction: direction))
    }
  }

  @MainActor
  @objc private func handleScrollPan(_ gr: UIPanGestureRecognizer) {
    guard isEnabled else { return }
    // When the user begins vertical scrolling, close any opened cell for consistency.
    guard gr.state == .began else { return }
    closeOpenedCell(animated: true)
  }

  @MainActor
  @objc private func handleTap(_ gr: UITapGestureRecognizer) {
    guard isEnabled else { return }
    guard configuration.tapToClose else { return }
    // Tap anywhere to close the opened cell.
    guard openedCell != nil else { return }
    closeOpenedCell(animated: true)
  }

  @MainActor
  @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
    guard isEnabled else { return }
    guard let scrollView else { return }

    // Resolve the target cell under finger.
    let location = gr.location(in: scrollView)
    guard let (cellView, indexPath) = resolveCell(at: location) else { return }
    guard let perCellConfig = provider?(indexPath) else { return }

    // Merge per-cell actions into current baseline configuration.
    // This keeps the manager lightweight while still allowing per-row customization.
    var effective = configuration
    effective.leftActions = perCellConfig.leftActions
    effective.rightActions = perCellConfig.rightActions
    effective.allowedDirections = perCellConfig.allowedDirections
    effective.openThreshold = perCellConfig.openThreshold
    effective.allowsOnlyOneOpen = perCellConfig.allowsOnlyOneOpen
    effective.tapToClose = perCellConfig.tapToClose
    effective.autoCloseAfterAction = perCellConfig.autoCloseAfterAction
    effective.usesRubberBand = perCellConfig.usesRubberBand
    effective.animationDuration = perCellConfig.animationDuration
    if let onEvent = perCellConfig.onEvent { effective.onEvent = onEvent }
    configuration = effective

    let translation = gr.translation(in: scrollView).x
    switch gr.state {
    case .began:
      // Enforce mutual exclusion early to avoid two cells staying open while switching targets.
      if configuration.allowsOnlyOneOpen, openedCell !== cellView {
        closeOpenedCell(animated: true)
      }
      initialTranslationX = currentTranslationX(for: cellView)
      configuration.onEvent?(.willBeginSwipe(indexPath: indexPath, direction: translation >= 0 ? .right : .left))
      prepareButtonsIfNeeded(for: cellView, indexPath: indexPath)
    case .changed:
      // Update translation (clamped / rubber-banded) and lay out button holder.
      let raw = initialTranslationX + translation
      let clamped = clampTranslation(raw)
      setCell(cellView, translationX: clamped, animated: false)
      updateButtonsLayout(for: cellView)
    case .ended, .cancelled, .failed:
      let final = currentTranslationX(for: cellView)
      settle(cellView: cellView, indexPath: indexPath, translationX: final)
    default:
      break
    }
  }
}

// MARK: - Global defaults storage (thread-safe)

private final class FKSwipeActionGlobalDefaults: @unchecked Sendable {
  static let shared = FKSwipeActionGlobalDefaults()

  // Simple lock-based storage to satisfy Swift 6 concurrency checks.
  private let lock = NSLock()
  private var _configuration = FKSwipeActionConfiguration()

  var configuration: FKSwipeActionConfiguration {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _configuration
    }
    set {
      lock.lock()
      _configuration = newValue
      lock.unlock()
    }
  }

  private init() {}
}

