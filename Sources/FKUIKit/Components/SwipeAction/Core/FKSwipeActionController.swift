//
// FKSwipeActionController.swift
//
// Gesture-driven swipe action controller attached to one cell view.
//

import UIKit

@MainActor
/// Gesture-driven controller that binds swipe actions to a single reusable cell view.
///
/// This type owns gesture handling, button layout, foreground translation, and open-state
/// transitions. It is designed to be reused safely in scrolling lists.
public final class FKSwipeActionController: NSObject {
  /// Current configuration.
  public private(set) var configuration: FKSwipeActionConfiguration = FKSwipeActionConfiguration()
  /// Delegate callback target.
  public weak var delegate: FKSwipeActionControllerDelegate?
  /// Whether action area is currently open.
  public private(set) var isOpen: Bool = false

  /// Host cell view that receives transforms and gestures.
  private weak var cellView: UIView?
  /// Parent scroll view used for gesture coordination and callback context.
  private weak var scrollView: UIScrollView?

  /// Background container that holds both left and right action stacks.
  private let actionContainerView = UIView()
  /// Mask overlay above foreground content, used for tap-to-close behavior.
  private let maskView = UIControl()
  /// Horizontal stack for left-side actions.
  private let leftStackView = UIStackView()
  /// Horizontal stack for right-side actions.
  private let rightStackView = UIStackView()
  /// Pan recognizer driving horizontal swipe interaction.
  private var panGestureRecognizer: UIPanGestureRecognizer?
  /// Cached button view references for fast teardown/rebuild.
  private var buttonViews: [FKSwipeActionButtonView] = []
  /// Current foreground translation offset.
  private var currentOffset: CGFloat = 0
  /// Offset snapshot captured at pan begin.
  private var beginOffset: CGFloat = 0

  /// Creates a controller for one cell.
  ///
  /// - Parameters:
  ///   - cellView: Host cell view receiving transforms and action background.
  ///   - scrollView: Parent list container for gesture coordination.
  public init(cellView: UIView, scrollView: UIScrollView?) {
    self.cellView = cellView
    self.scrollView = scrollView
    super.init()
    setupIfNeeded()
    FKSwipeActionManager.shared.register(controller: self)
  }

  /// Applies a new configuration and rebuilds button views.
  ///
  /// This call is reuse-safe and should be executed whenever cell content changes.
  ///
  /// - Parameter configuration: Full configuration for left/right actions and behavior.
  public func configure(_ configuration: FKSwipeActionConfiguration) {
    assert(Thread.isMainThread, "FKSwipeAction must be used on main thread.")
    self.configuration = configuration
    rebuildButtons()
    updateContainerAppearance()
    close(animated: false)
  }

  /// Opens left or right actions if available.
  ///
  /// - Parameters:
  ///   - side: Side to reveal.
  ///   - animated: Whether transition should be animated.
  public func open(side: FKSwipeActionSide, animated: Bool = true) {
    guard configuration.behavior.isEnabled, !configuration.behavior.isLocked else { return }
    let target = side == .left ? leftRevealWidth : -rightRevealWidth
    guard target != 0 else { return }
    FKSwipeActionManager.shared.notifyWillOpen(self, exclusive: configuration.behavior.allowsOnlyOneOpenCell)
    setOffset(target, animated: animated)
  }

  /// Closes swipe actions.
  ///
  /// - Parameter animated: Whether close transition should be animated.
  public func close(animated: Bool = true) {
    setOffset(0, animated: animated)
  }

  /// Enables or disables interaction quickly.
  ///
  /// - Parameter enabled: Interaction switch for this host controller.
  public func setEnabled(_ enabled: Bool) {
    configuration.behavior.isEnabled = enabled
    panGestureRecognizer?.isEnabled = enabled
    if !enabled {
      close(animated: true)
    }
  }

  /// Returns current side if opened.
  ///
  /// - Returns: Opened side or `nil` when fully closed.
  public func openedSide() -> FKSwipeActionSide? {
    if currentOffset > 0 { return .left }
    if currentOffset < 0 { return .right }
    return nil
  }

  /// Total reveal width required for left-side actions.
  private var leftRevealWidth: CGFloat {
    totalWidth(for: configuration.leftActions)
  }

  /// Total reveal width required for right-side actions.
  private var rightRevealWidth: CGFloat {
    totalWidth(for: configuration.rightActions)
  }

  /// Builds static container hierarchy, constraints, and gesture recognizer.
  ///
  /// This method runs once during controller initialization.
  private func setupIfNeeded() {
    guard let cellView else { return }
    // Action buttons live behind foreground content and remain static while content moves.
    actionContainerView.translatesAutoresizingMaskIntoConstraints = false
    actionContainerView.isUserInteractionEnabled = true
    cellView.insertSubview(actionContainerView, at: 0)
    NSLayoutConstraint.activate([
      actionContainerView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor),
      actionContainerView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
      actionContainerView.topAnchor.constraint(equalTo: cellView.topAnchor),
      actionContainerView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
    ])

    // Prepare horizontal stacks for both reveal directions.
    leftStackView.axis = .horizontal
    leftStackView.alignment = .fill
    leftStackView.distribution = .fill
    leftStackView.translatesAutoresizingMaskIntoConstraints = false

    rightStackView.axis = .horizontal
    rightStackView.alignment = .fill
    rightStackView.distribution = .fill
    rightStackView.translatesAutoresizingMaskIntoConstraints = false

    // Pin stacks to container with configurable insets.
    actionContainerView.addSubview(leftStackView)
    actionContainerView.addSubview(rightStackView)
    NSLayoutConstraint.activate([
      leftStackView.leadingAnchor.constraint(equalTo: actionContainerView.leadingAnchor, constant: configuration.appearance.actionInsets.left),
      leftStackView.topAnchor.constraint(equalTo: actionContainerView.topAnchor, constant: configuration.appearance.actionInsets.top),
      leftStackView.bottomAnchor.constraint(equalTo: actionContainerView.bottomAnchor, constant: -configuration.appearance.actionInsets.bottom),

      rightStackView.trailingAnchor.constraint(equalTo: actionContainerView.trailingAnchor, constant: -configuration.appearance.actionInsets.right),
      rightStackView.topAnchor.constraint(equalTo: actionContainerView.topAnchor, constant: configuration.appearance.actionInsets.top),
      rightStackView.bottomAnchor.constraint(equalTo: actionContainerView.bottomAnchor, constant: -configuration.appearance.actionInsets.bottom)
    ])

    // Mask sits above foreground content and receives tap-to-close interactions.
    maskView.translatesAutoresizingMaskIntoConstraints = false
    maskView.backgroundColor = .clear
    maskView.alpha = 0
    maskView.addTarget(self, action: #selector(didTapMask), for: .touchUpInside)
    cellView.addSubview(maskView)
    NSLayoutConstraint.activate([
      maskView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor),
      maskView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
      maskView.topAnchor.constraint(equalTo: cellView.topAnchor),
      maskView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
    ])

    // One pan gesture per cell controls all swipe state transitions.
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    cellView.addGestureRecognizer(pan)
    panGestureRecognizer = pan
  }

  /// Recreates left/right action button views from current configuration.
  ///
  /// This ensures reused cells always render the latest button set and style.
  private func rebuildButtons() {
    // Clear stale button references and stack arranged subviews.
    buttonViews.forEach { $0.removeFromSuperview() }
    buttonViews.removeAll()
    leftStackView.arrangedSubviews.forEach {
      leftStackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    rightStackView.arrangedSubviews.forEach {
      rightStackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    // Apply stack spacing from current appearance configuration.
    leftStackView.spacing = configuration.appearance.itemSpacing
    rightStackView.spacing = configuration.appearance.itemSpacing

    // Build and append left-side buttons.
    for (index, item) in configuration.leftActions.enumerated() {
      let button = makeButton(item: item, index: index, side: .left)
      leftStackView.addArrangedSubview(button)
      buttonViews.append(button)
      // Respect fixed width when provided by style.
      if let width = item.style.fixedWidth {
        button.widthAnchor.constraint(equalToConstant: max(44, width)).isActive = true
      }
    }
    // Build and append right-side buttons.
    for (index, item) in configuration.rightActions.enumerated() {
      let button = makeButton(item: item, index: index, side: .right)
      rightStackView.addArrangedSubview(button)
      buttonViews.append(button)
      // Respect fixed width when provided by style.
      if let width = item.style.fixedWidth {
        button.widthAnchor.constraint(equalToConstant: max(44, width)).isActive = true
      }
    }
  }

  /// Creates one button view and wires its tap callback to controller routing.
  ///
  /// - Parameters:
  ///   - item: Action item model.
  ///   - index: Action index inside its side array.
  ///   - side: Side that owns the action.
  /// - Returns: Configured button view.
  private func makeButton(item: FKSwipeActionItem, index: Int, side: FKSwipeActionSide) -> FKSwipeActionButtonView {
    let button = FKSwipeActionButtonView(item: item)
    button.tapHandler = { [weak self] in
      self?.handleActionTap(item: item, index: index, side: side)
    }
    return button
  }

  /// Applies visual appearance and interaction switches from configuration.
  private func updateContainerAppearance() {
    actionContainerView.backgroundColor = configuration.appearance.actionAreaBackgroundColor
    maskView.backgroundColor = configuration.appearance.maskColor
    panGestureRecognizer?.isEnabled = configuration.behavior.isEnabled
  }

  /// Commits foreground offset and synchronizes open-state bookkeeping.
  ///
  /// - Parameters:
  ///   - offset: Target horizontal translation offset.
  ///   - animated: Whether state transition should animate.
  private func setOffset(_ offset: CGFloat, animated: Bool) {
    // Clamp to total reveal width to avoid overshooting final open states.
    let clamped = max(-rightRevealWidth, min(leftRevealWidth, offset))
    let isOpening = clamped != 0
    let duration = animated ? configuration.behavior.animationDuration : 0

    // Notify manager before opening to enforce optional mutual exclusion.
    if isOpening {
      FKSwipeActionManager.shared.notifyWillOpen(self, exclusive: configuration.behavior.allowsOnlyOneOpenCell)
    }

    // Animate foreground translation and mask alpha together.
    let animations = { [weak self] in
      guard let self else { return }
      self.applyForegroundTransform(x: clamped)
      self.maskView.alpha = abs(clamped) > 0 ? 1 : 0
    }
    // Finalize state flags and delegate callback after transition completes.
    let completion: (Bool) -> Void = { [weak self] _ in
      guard let self else { return }
      self.currentOffset = clamped
      self.isOpen = clamped != 0
      self.maskView.isUserInteractionEnabled = self.isOpen && self.configuration.behavior.closesWhenTapMask
      // Clear manager pointer once controller is fully closed.
      if !self.isOpen {
        FKSwipeActionManager.shared.notifyDidClose(self)
      }
      self.delegate?.swipeActionController(self, didChangeOpenState: self.isOpen)
    }

    // Use spring animation for smooth swipe behavior and rebound.
    if animated {
      FKSwipeActionAnimator.animateOffset(duration: duration, animations: animations, completion: completion)
    } else {
      animations()
      completion(true)
    }
  }

  /// Applies horizontal translation to foreground subviews.
  ///
  /// - Parameter x: Horizontal translation in points.
  private func applyForegroundTransform(x: CGFloat) {
    // Move every foreground subview except action container and overlay mask.
    guard let cellView else { return }
    for subview in cellView.subviews where subview !== actionContainerView && subview !== maskView {
      subview.transform = CGAffineTransform(translationX: x, y: 0)
    }
  }

  /// Calculates total reveal width for one side action array.
  ///
  /// - Parameter items: Side action models.
  /// - Returns: Combined width including insets and inter-item spacing.
  private func totalWidth(for items: [FKSwipeActionItem]) -> CGFloat {
    let spacingCount = max(0, items.count - 1)
    var total = CGFloat(spacingCount) * configuration.appearance.itemSpacing
    total += configuration.appearance.actionInsets.left + configuration.appearance.actionInsets.right
    for item in items {
      // Fixed width branch for deterministic layout.
      if let fixed = item.style.fixedWidth {
        total += max(44, fixed)
      } else {
        // Adaptive width branch based on title/icon/insets.
        let titleWidth = item.title.map {
          ($0 as NSString).size(withAttributes: [.font: item.style.titleFont]).width
        } ?? 0
        let imageWidth = item.image.flatMap { _ in item.style.imageSize?.width ?? 20 } ?? 0
        let imageTitleSpacing = (item.image != nil && !(item.title?.isEmpty ?? true)) ? item.style.imageTitleSpacing : 0
        let autoWidth = item.style.contentInsets.left + titleWidth + imageWidth + imageTitleSpacing + item.style.contentInsets.right
        total += max(item.style.minimumWidth, autoWidth)
      }
    }
    return total
  }

  /// Handles button tap routing, optional confirmation, and auto-close behavior.
  ///
  /// - Parameters:
  ///   - item: Tapped action item.
  ///   - index: Action index in side array.
  ///   - side: Side that owns the tapped action.
  private func handleActionTap(item: FKSwipeActionItem, index: Int, side: FKSwipeActionSide) {
    guard item.isEnabled else { return }
    // Build callback context from current host references.
    let invoke = { [weak self] in
      guard let self else { return }
      let context = FKSwipeActionContext(
        cell: self.cellView,
        scrollView: self.scrollView,
        item: item,
        index: index,
        side: side
      )
      item.handler?(context)
      // Auto-close is enabled for most list action flows.
      if item.autoCloseOnTap {
        self.close(animated: true)
      }
    }

    // Dangerous actions can require explicit user confirmation.
    if item.requiresConfirmation {
      presentConfirmation(for: item, confirmHandler: invoke)
    } else {
      invoke()
    }
  }

  /// Presents confirmation alert before executing dangerous actions.
  ///
  /// - Parameters:
  ///   - item: Action item carrying alert texts.
  ///   - confirmHandler: Callback executed when user confirms.
  private func presentConfirmation(for item: FKSwipeActionItem, confirmHandler: @escaping () -> Void) {
    // Fallback: execute directly when no presenter can be resolved.
    guard let presenter = cellView?.fk_parentViewController else {
      confirmHandler()
      return
    }
    let alert = UIAlertController(
      title: item.confirmationTitle,
      message: item.confirmationMessage,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: item.confirmationCancelTitle, style: .cancel))
    alert.addAction(UIAlertAction(title: item.confirmationActionTitle, style: .destructive) { _ in
      confirmHandler()
    })
    presenter.present(alert, animated: true)
  }

  /// Handles mask tap and closes current opened state when enabled.
  @objc private func didTapMask() {
    guard configuration.behavior.closesWhenTapMask else { return }
    close(animated: true)
  }

  /// Main pan gesture handler driving interactive swipe transition.
  ///
  /// - Parameter recognizer: Pan recognizer attached to host cell view.
  @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.behavior.isEnabled, !configuration.behavior.isLocked, FKSwipeActionManager.shared.isGloballyEnabled else {
      return
    }
    switch recognizer.state {
    case .began:
      // Store baseline offset so partial-open state can continue smoothly.
      beginOffset = currentOffset
    case .changed:
      // Apply interactive translation with optional elastic over-scroll.
      let translation = recognizer.translation(in: cellView).x
      var next = beginOffset + translation
      next = constrainedOffset(with: next)
      applyForegroundTransform(x: next)
      maskView.alpha = abs(next) > 0 ? 1 : 0
    case .ended, .cancelled, .failed:
      // Commit final state using threshold and velocity heuristics.
      let translation = recognizer.translation(in: cellView).x
      let velocityX = recognizer.velocity(in: cellView).x
      finishPan(translation: translation, velocityX: velocityX)
    default:
      break
    }
  }

  /// Applies boundary and optional elastic behavior for interactive offsets.
  ///
  /// - Parameter value: Raw interactive translation value.
  /// - Returns: Constrained/elastic-corrected translation.
  private func constrainedOffset(with value: CGFloat) -> CGFloat {
    let minOffset = -rightRevealWidth
    let maxOffset = leftRevealWidth
    guard configuration.behavior.allowsElasticOverscroll else {
      return min(max(value, minOffset), maxOffset)
    }
    // Soft clamp with resistance when crossing reveal limits.
    if value > maxOffset {
      let overflow = value - maxOffset
      return maxOffset + (overflow * 0.35)
    }
    if value < minOffset {
      let overflow = minOffset - value
      return minOffset - (overflow * 0.35)
    }
    return value
  }

  /// Resolves final open/close target when pan interaction ends.
  ///
  /// - Parameters:
  ///   - translation: Final pan translation.
  ///   - velocityX: Final horizontal velocity.
  private func finishPan(translation: CGFloat, velocityX: CGFloat) {
    let predicted = beginOffset + translation
    let leftThreshold = leftRevealWidth * configuration.behavior.openThresholdRatio
    let rightThreshold = rightRevealWidth * configuration.behavior.openThresholdRatio

    // Velocity has higher priority to keep swipe interactions responsive.
    let target: CGFloat
    if velocityX > 600 {
      target = leftRevealWidth
    } else if velocityX < -600 {
      target = -rightRevealWidth
    } else if predicted > leftThreshold {
      target = leftRevealWidth
    } else if predicted < -rightThreshold {
      target = -rightRevealWidth
    } else {
      target = 0
    }

    setOffset(target, animated: true)
  }
}

extension FKSwipeActionController: UIGestureRecognizerDelegate {
  /// Decides whether horizontal swipe recognition should start.
  ///
  /// - Parameter gestureRecognizer: Candidate gesture recognizer.
  /// - Returns: `true` when gesture should begin for current configuration.
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panGestureRecognizer else { return true }
    guard configuration.behavior.isEnabled, !configuration.behavior.isLocked else { return false }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = cellView else { return false }

    // Ignore vertical-dominant pans to keep list scrolling smooth.
    let velocity = pan.velocity(in: view)
    if abs(velocity.x) <= abs(velocity.y) {
      return false
    }
    // Optional edge-only mode reduces accidental swipes during list browsing.
    switch configuration.behavior.triggerMode {
    case .fullWidth:
      return true
    case .edgeOnly(let edgeWidth):
      let location = pan.location(in: view)
      return location.x <= edgeWidth || location.x >= (view.bounds.width - edgeWidth)
    }
  }

  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Allow simultaneous recognition with parent scroll pan for natural handoff.
    if let scrollView, otherGestureRecognizer === scrollView.panGestureRecognizer {
      return true
    }
    return false
  }
}

private extension UIView {
  /// Traverses responder chain to find nearest owning view controller.
  var fk_parentViewController: UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let viewController = current as? UIViewController {
        return viewController
      }
      responder = current.next
    }
    return nil
  }
}
