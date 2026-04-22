import UIKit

@MainActor
extension FKSwipeActionManager {
  func openCell(_ cellView: UIView, indexPath: IndexPath, direction: FKSwipeActionConfiguration.Direction, width: CGFloat) {
    // Snap cell content to the fully-open position and record open state.
    if configuration.allowsOnlyOneOpen, openedCell !== cellView {
      closeOpenedCell(animated: true)
    }
    openedCell = cellView
    openedIndexPath = indexPath
    openedDirection = direction
    setCell(cellView, translationX: direction.contains(.left) ? -width : width, animated: true)
    configuration.onEvent?(.didEndSwipe(indexPath: indexPath, isOpen: true, direction: direction))
  }

  func settle(cellView: UIView, indexPath: IndexPath, translationX: CGFloat) {
    // Decide whether to open or close based on release translation and configured threshold.
    let direction: FKSwipeActionConfiguration.Direction? = translationX < 0 ? .left : (translationX > 0 ? .right : nil)
    let maxWidth = abs(maxRevealWidth(for: direction))

    if abs(translationX) >= max(configuration.openThreshold, maxWidth * 0.5), maxWidth > 0, let direction {
      openCell(cellView, indexPath: indexPath, direction: direction, width: maxWidth)
      return
    }

    // If it was previously open, keep it open when user swipes slightly back.
    if openedCell === cellView, let openedDirection, maxWidth > 0, abs(translationX) > 8 {
      openCell(cellView, indexPath: indexPath, direction: openedDirection, width: maxWidth)
      return
    }

    openedCell = nil
    openedIndexPath = nil
    openedDirection = nil
    setCell(cellView, translationX: 0, animated: true)
    configuration.onEvent?(.didEndSwipe(indexPath: indexPath, isOpen: false, direction: direction))
  }

  func prepareButtonsIfNeeded(for cellView: UIView, indexPath: IndexPath) {
    // Lazily create/update the button holder behind the cell.
    let holder = ensureButtonsHolder(in: cellView)
    let left = configuration.leftActions
    let right = configuration.rightActions
    holder.configure(left: left, right: right) { [weak self] actionID, handler in
      guard let self else { return }
      self.configuration.onEvent?(.didTapAction(indexPath: indexPath, actionID: actionID))
      handler?()
      if self.configuration.autoCloseAfterAction {
        self.closeOpenedCell(animated: true)
      }
    }
    updateButtonsLayout(for: cellView)
  }

  func updateButtonsLayout(for cellView: UIView) {
    // Keep the holder aligned with cell bounds; use frame/autoresizing for performance.
    guard let holder = objc_getAssociatedObject(cellView, &FKSwipeAssociationKey.holder) as? FKSwipeButtonsHolder else { return }
    holder.frame = cellView.bounds
    holder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    holder.updateLayout(contentTranslationX: currentTranslationX(for: cellView))
  }

  func clampTranslation(_ raw: CGFloat) -> CGFloat {
    // Clamp translation to available actions and allowed directions, with optional rubber-band.
    let leftMax = maxRevealWidth(for: .right)
    let rightMax = maxRevealWidth(for: .left)

    // Allowed directions and available actions decide limits.
    var minX: CGFloat = 0
    var maxX: CGFloat = 0
    if configuration.allowedDirections.contains(.left), rightMax < 0 { minX = rightMax }
    if configuration.allowedDirections.contains(.right), leftMax > 0 { maxX = leftMax }

    if raw < minX {
      return configuration.usesRubberBand ? rubberBand(raw, limit: minX) : minX
    }
    if raw > maxX {
      return configuration.usesRubberBand ? rubberBand(raw, limit: maxX) : maxX
    }
    return raw
  }

  func rubberBand(_ value: CGFloat, limit: CGFloat) -> CGFloat {
    // A simple resistance curve similar to UIScrollView rubber band.
    let delta = value - limit
    let sign: CGFloat = delta >= 0 ? 1 : -1
    let absDelta = abs(delta)
    let resistance = absDelta / (absDelta + 120)
    return limit + sign * (absDelta * (1 - resistance))
  }

  func maxRevealWidth(for direction: FKSwipeActionConfiguration.Direction?) -> CGFloat {
    // Compute the total reveal width as the sum of button widths on the target side.
    guard let direction else { return 0 }
    switch direction {
    case .left:
      let w = configuration.rightActions.reduce(CGFloat(0)) { $0 + max(0, $1.width) }
      return -w
    case .right:
      let w = configuration.leftActions.reduce(CGFloat(0)) { $0 + max(0, $1.width) }
      return w
    default:
      return 0
    }
  }

  func setCell(_ cellView: UIView, translationX: CGFloat, animated: Bool) {
    // Apply translation by moving the cell's contentView, leaving buttons behind.
    guard let contentView = resolveCellContentView(cellView) else { return }
    let apply = { contentView.transform = CGAffineTransform(translationX: translationX, y: 0) }
    if !animated {
      apply()
      return
    }
    // Use UIView animation with beginFromCurrentState to keep interaction responsive.
    UIView.animate(withDuration: configuration.animationDuration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
      apply()
    }
  }

  func currentTranslationX(for cellView: UIView) -> CGFloat {
    // Read current translation from contentView transform.
    resolveCellContentView(cellView)?.transform.tx ?? 0
  }

  func resolveCellContentView(_ cellView: UIView) -> UIView? {
    // Support both table and collection cells without requiring protocol conformance.
    if let cell = cellView as? UITableViewCell { return cell.contentView }
    if let cell = cellView as? UICollectionViewCell { return cell.contentView }
    return nil
  }

  func resolveCell(at point: CGPoint) -> (UIView, IndexPath)? {
    // Hit-test indexPath using the underlying list APIs.
    guard let scrollView else { return nil }
    if let table = scrollView as? UITableView {
      guard let indexPath = table.indexPathForRow(at: point) else { return nil }
      guard let cell = table.cellForRow(at: indexPath) else { return nil }
      return (cell, indexPath)
    }
    if let collection = scrollView as? UICollectionView {
      guard let indexPath = collection.indexPathForItem(at: point) else { return nil }
      guard let cell = collection.cellForItem(at: indexPath) else { return nil }
      return (cell, indexPath)
    }
    return nil
  }

  func ensureButtonsHolder(in cellView: UIView) -> FKSwipeButtonsHolder {
    // Create the holder once and associate it with the cell view.
    if let holder = objc_getAssociatedObject(cellView, &FKSwipeAssociationKey.holder) as? FKSwipeButtonsHolder {
      return holder
    }
    let holder = FKSwipeButtonsHolder()
    holder.isUserInteractionEnabled = true
    // Put buttons behind contentView without touching business subviews.
    cellView.insertSubview(holder, at: 0)
    objc_setAssociatedObject(cellView, &FKSwipeAssociationKey.holder, holder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return holder
  }
}

