import ObjectiveC
import UIKit

private enum FKStickyAssociationKey {
  nonisolated(unsafe) static var engine: UInt8 = 0
  nonisolated(unsafe) static var provider: UInt8 = 0
  nonisolated(unsafe) static var autoRefreshToken: UInt8 = 0
}

private final class FKStickyTargetsProviderBox {
  let provider: (UIScrollView) -> [FKStickyTarget]

  init(provider: @escaping (UIScrollView) -> [FKStickyTarget]) {
    self.provider = provider
  }
}

private final class FKStickyDisplayLinkDriver {
  private weak var scrollView: UIScrollView?
  private weak var engine: FKStickyEngine?
  private var link: CADisplayLink?

  func attach(scrollView: UIScrollView, engine: FKStickyEngine) {
    self.scrollView = scrollView
    self.engine = engine
  }

  func start() {
    guard link == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(tick))
    link.add(to: .main, forMode: .common)
    self.link = link
  }

  deinit {
    link?.invalidate()
  }

  @objc
  private func tick() {
    guard let scrollView else { return }
    guard scrollView.window != nil else { return }
    if !scrollView.isDragging, !scrollView.isDecelerating, !scrollView.isTracking {
      return
    }
    // Keep layout stable at 60fps during scrolling.
    // Targets should be reloaded only when layout changes (e.g. after reloadData / rotation).
    scrollView.fk_stickyEngine.reloadLayout()
  }
}

public extension UIScrollView {
  /// Sticky engine bound to this scroll view.
  var fk_stickyEngine: FKStickyEngine {
    if let cached = objc_getAssociatedObject(self, &FKStickyAssociationKey.engine) as? FKStickyEngine {
      return cached
    }
    let engine = FKStickyEngine(
      scrollView: self,
      configuration: FKStickyManager.shared.templateConfiguration
    )
    objc_setAssociatedObject(
      self,
      &FKStickyAssociationKey.engine,
      engine,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    return engine
  }

  /// Enables sticky headers with one call.
  ///
  /// - Parameters:
  ///   - configuration: Optional per-list configuration override.
  ///   - provider: Target provider called on each layout update.
  func fk_enableStickyHeaders(
    configuration: FKStickyConfiguration? = nil,
    provider: @escaping (UIScrollView) -> [FKStickyTarget]
  ) {
    runOnMain { [weak self] in
      guard let self else { return }
      if let configuration {
        self.fk_stickyEngine.apply(configuration: configuration)
      }
      let box = FKStickyTargetsProviderBox(provider: provider)
      objc_setAssociatedObject(self, &FKStickyAssociationKey.provider, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      self.fk_reloadStickyTargets()
      self.ensureAutoRefreshDriver()
    }
  }

  /// Reloads sticky targets via registered provider.
  func fk_reloadStickyTargets() {
    runOnMain { [weak self] in
      guard
        let self,
        let box = objc_getAssociatedObject(self, &FKStickyAssociationKey.provider) as? FKStickyTargetsProviderBox
      else {
        return
      }
      self.fk_stickyEngine.setTargets(box.provider(self))
    }
  }

  /// Handles scroll event and updates sticky layout.
  func fk_handleStickyScroll() {
    fk_stickyEngine.handleScroll()
  }

  /// Recomputes sticky layout manually.
  func fk_reloadStickyLayout() {
    fk_stickyEngine.reloadLayout()
  }

  /// Clears sticky state and transforms.
  func fk_resetSticky() {
    fk_stickyEngine.resetStickyState()
  }

  /// Enables section sticky behavior for table views.
  ///
  /// This method does not require subclassing your existing list.
  func fk_enableSectionStickyHeaders(
    configuration: FKStickyConfiguration? = nil,
    makeTarget: ((_ section: Int, _ view: UIView) -> FKStickyTarget?)? = nil
  ) {
    guard let tableView = self as? UITableView else { return }
    fk_enableStickyHeaders(configuration: configuration) { _ in
      let sections = tableView.numberOfSections
      guard sections > 0 else { return [] }
      return (0..<sections).compactMap { section in
        if let makeTarget, let header = tableView.headerView(forSection: section) {
          return makeTarget(section, header)
        }
        return FKStickyTarget(
          id: "fk_table_section_\(section)",
          viewProvider: { [weak tableView] in
            tableView?.headerView(forSection: section)
          },
          threshold: tableView.rectForHeader(inSection: section).minY
        )
      }
    }
  }

  /// Enables section sticky behavior for collection views.
  func fk_enableSectionStickyHeaders(
    configuration: FKStickyConfiguration? = nil,
    elementKind: String = UICollectionView.elementKindSectionHeader,
    makeTarget: ((_ section: Int, _ view: UICollectionReusableView, _ frame: CGRect) -> FKStickyTarget?)? = nil
  ) {
    guard let collectionView = self as? UICollectionView else { return }
    fk_enableStickyHeaders(configuration: configuration) { _ in
      let sections = collectionView.numberOfSections
      guard sections > 0 else { return [] }
      return (0..<sections).compactMap { section in
        let indexPath = IndexPath(item: 0, section: section)
        guard let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(
          ofKind: elementKind,
          at: indexPath
        ) else {
          return nil
        }

        if let makeTarget, let header = collectionView.supplementaryView(forElementKind: elementKind, at: indexPath) {
          return makeTarget(section, header, attributes.frame)
        }
        return FKStickyTarget(
          id: "fk_collection_section_\(section)",
          viewProvider: { [weak collectionView] in
            collectionView?.supplementaryView(forElementKind: elementKind, at: indexPath)
          },
          threshold: attributes.frame.minY
        )
      }
    }
  }

  private func ensureAutoRefreshDriver() {
    if let driver = objc_getAssociatedObject(self, &FKStickyAssociationKey.autoRefreshToken) as? FKStickyDisplayLinkDriver {
      driver.start()
      return
    }
    let driver = FKStickyDisplayLinkDriver()
    driver.attach(scrollView: self, engine: fk_stickyEngine)
    driver.start()
    objc_setAssociatedObject(self, &FKStickyAssociationKey.autoRefreshToken, driver, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  private func runOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }
}
