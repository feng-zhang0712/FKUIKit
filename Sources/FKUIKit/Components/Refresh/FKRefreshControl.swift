//
// FKRefreshControl.swift
// FKUIKit — FKRefresh
//
// Core control: observes scroll offset / insets, drives state machine, adjusts header `contentInset`
// only for pull-to-refresh. Attach via `UIScrollView.fk_addPullToRefresh` / `fk_addLoadMore` only.
//

import UIKit

/// The direction / role of a refresh control.
public enum FKRefreshKind {
  case pullToRefresh
  case loadMore
}

/// Core refresh control. Attach to any `UIScrollView` via `UIScrollView` helpers.
/// Do not add this view manually — use `fk_addPullToRefresh` / `fk_addLoadMore`.
public final class FKRefreshControl: UIView {

  // MARK: - Public

  public let kind: FKRefreshKind

  /// Current state. Mutate only through the public `begin*` / `end*` APIs.
  public private(set) var state: FKRefreshState = .idle {
    didSet {
      guard state != oldValue else { return }
      handleStateTransition(from: oldValue, to: state)
    }
  }

  /// Latest pull progress for a header (`0...1`). Always `0` for footers.
  public private(set) var currentPullProgress: CGFloat = 0

  public var configuration: FKRefreshConfiguration {
    didSet { applyConfiguration() }
  }

  /// When `false`, user triggers and programmatic `begin*` are ignored.
  public var isEnabled: Bool = true

  public weak var delegate: FKRefreshControlDelegate?

  /// Primary callback when the user (or `begin*`) starts an action.
  public var actionHandler: FKVoidHandler?

  /// Observe state without a delegate.
  public var onStateChanged: ((_ control: FKRefreshControl, _ state: FKRefreshState) -> Void)?

  /// Replace to customise appearance (GIF, Lottie hosted in `UIView`, etc.).
  public var contentView: FKRefreshContentView {
    didSet {
      oldValue.removeFromSuperview()
      embedContentView(contentView)
      contentView.refreshControl(self, didTransitionTo: state, from: state)
    }
  }

  // MARK: - Private

  private weak var scrollView: UIScrollView?
  private var scrollOffsetObservation: NSKeyValueObservation?
  private var panGestureObservation: NSKeyValueObservation?
  private var contentSizeObservation: NSKeyValueObservation?
  private var contentInsetObservation: NSKeyValueObservation?
  private var boundsObservation: NSKeyValueObservation?

  /// Baseline insets captured while the control is not mutating `contentInset` / indicators.
  private var baselineContentInset: UIEdgeInsets = .zero
  private var baselineVerticalIndicatorInsets: UIEdgeInsets = .zero

  private var isAnimatingCollapse = false
  private var hapticGenerator: UIImpactFeedbackGenerator?
  /// Prevents re-entrant KVO when we mutate `contentInset` ourselves.
  private var isUpdatingInset = false
  private var loadingStartedAt: Date?
  private var pendingEndWorkItem: DispatchWorkItem?

  // MARK: - Init

  public init(
    kind: FKRefreshKind,
    configuration: FKRefreshConfiguration = .default,
    contentView: FKRefreshContentView? = nil,
    action: FKVoidHandler? = nil
  ) {
    self.kind = kind
    self.configuration = configuration
    let cv = contentView ?? FKDefaultRefreshContentView()
    self.contentView = cv
    self.actionHandler = action
    super.init(frame: .zero)
    clipsToBounds = true
    embedContentView(cv)
    wireRetryTapIfNeeded(cv)
    if configuration.isHapticFeedbackEnabled {
      hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
      hapticGenerator?.prepare()
    }
  }

  public required init?(coder: NSCoder) {
    fatalError("Use init(kind:configuration:contentView:action:)")
  }

  // MARK: - Attachment

  func attach(to scrollView: UIScrollView) {
    detach()
    self.scrollView = scrollView
    captureScrollViewBaselines(scrollView)
    translatesAutoresizingMaskIntoConstraints = true
    scrollView.addSubview(self)
    setupFrameForKind()
    startObserving()
    if kind == .loadMore {
      updateFooterVisibility(for: scrollView)
    }
  }

  func detach() {
    stopObserving()
    pendingEndWorkItem?.cancel()
    pendingEndWorkItem = nil
    removeFromSuperview()
    scrollView = nil
  }

  // MARK: - Public control

  /// Programmatically begin pull-to-refresh or silent refresh.
  public func beginRefreshing(animated: Bool = true) {
    ensureMain { self.beginRefreshingOnMain(animated: animated) }
  }

  /// Programmatically begin load-more (same semantics as an automatic bottom trigger).
  public func beginLoadingMore() {
    ensureMain { self.beginLoadingMoreOnMain() }
  }

  /// Successful completion (header or footer).
  public func endRefreshing() {
    ensureMain { self.endRefreshingOnMain(outcome: .success) }
  }

  /// Footer convenience — identical to ``endRefreshing``.
  public func endLoadingMore() {
    endRefreshing()
  }

  /// Header: refresh succeeded but the first page has no rows.
  public func endRefreshingWithEmptyList() {
    ensureMain { self.endRefreshingOnMain(outcome: .emptyList) }
  }

  /// Footer: pagination is exhausted.
  public func endRefreshingWithNoMoreData() {
    ensureMain { self.endRefreshingOnMain(outcome: .noMoreData) }
  }

  /// Any failure path — shows retry affordance on the bundled default footer.
  public func endRefreshingWithError(_ error: Error? = nil) {
    ensureMain { self.endRefreshingOnMain(outcome: .failure(error)) }
  }

  /// Clears `.noMoreData` / `.failed` and returns to `.idle`.
  public func resetToIdle() {
    ensureMain { self.resetToIdleOnMain() }
  }

  /// Called internally after a successful pull-to-refresh begins expanding the header.
  public func resetFooterAfterPullToRefresh() {
    ensureMain { self.resetFooterAfterPullToRefreshOnMain() }
  }

  /// Re-run the load-more action after `.failed` (also used by the default “tap to retry”).
  public func retryAfterFailure() {
    ensureMain { self.retryAfterFailureOnMain() }
  }

  // MARK: - Main queue

  private func ensureMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }

  private func beginRefreshingOnMain(animated: Bool) {
    guard isEnabled else { return }
    guard kind == .pullToRefresh else { return }
    guard state != .refreshing else { return }
    guard let scrollView else { return }

    scrollView.fk_resetLoadMoreAfterPullToRefresh()

    if configuration.isSilentRefresh {
      alpha = 0
      isUserInteractionEnabled = false
      transition(to: .refreshing)
      markLoadingStart()
      fireAction()
      return
    }

    alpha = 1
    isUserInteractionEnabled = true
    transition(to: .refreshing)
    markLoadingStart()
    if animated && configuration.shouldKeepExpandedWhileRefreshing {
      expandScrollView(scrollView)
      let targetOffsetY = -(baselineContentInset.top + configuration.expandedHeight)
      if scrollView.contentOffset.y > targetOffsetY {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
          scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: targetOffsetY)
        }
      }
    }
    fireAction()
  }

  private func beginLoadingMoreOnMain() {
    guard isEnabled else { return }
    guard kind == .loadMore else { return }
    guard state == .idle else { return }
    guard let scrollView else { return }
    guard !isFooterHiddenForShortContent(scrollView) else { return }
    transition(to: .refreshing)
    markLoadingStart()
    fireAction()
  }

  private enum EndOutcome {
    case success
    case emptyList
    case noMoreData
    case failure(Error?)
  }

  private func endRefreshingOnMain(outcome: EndOutcome) {
    switch outcome {
    case .success:
      guard state == .refreshing || state == .triggered else { return }
      transition(to: .finished)
    case .emptyList:
      guard kind == .pullToRefresh else { return }
      guard state == .refreshing || state == .triggered else { return }
      transition(to: .listEmpty)
    case .noMoreData:
      guard kind == .loadMore else { return }
      guard state == .refreshing || state == .triggered else { return }
      transition(to: .noMoreData)
    case .failure(let error):
      guard state == .refreshing || state == .triggered else { return }
      transition(to: .failed(error))
    }

    runMinimumVisibilityIfNeeded { [weak self] in
      guard let self else { return }
      if self.kind == .pullToRefresh {
        if self.configuration.isSilentRefresh {
          self.alpha = 1
          self.isUserInteractionEnabled = true
        }
        self.scheduleCollapse(delay: self.configuration.finishedHoldDuration)
      } else {
        self.scheduleFooterCompletion()
      }
    }
  }

  private func resetToIdleOnMain() {
    transition(to: .idle)
    if kind == .pullToRefresh {
      collapseScrollView(animated: false)
    }
    if let scrollView {
      updateFooterVisibility(for: scrollView)
    }
  }

  private func resetFooterAfterPullToRefreshOnMain() {
    guard kind == .loadMore else { return }
    transition(to: .idle)
    if let scrollView {
      updateFooterVisibility(for: scrollView)
    }
  }

  private func retryAfterFailureOnMain() {
    guard isEnabled else { return }
    guard kind == .loadMore else { return }
    guard case .failed = state else { return }
    guard let scrollView, !isFooterHiddenForShortContent(scrollView) else { return }
    transition(to: .refreshing)
    markLoadingStart()
    fireAction()
  }

  // MARK: - Frame setup

  private func captureScrollViewBaselines(_ scrollView: UIScrollView) {
    baselineContentInset = scrollView.contentInset
    baselineVerticalIndicatorInsets = scrollView.verticalScrollIndicatorInsets
  }

  private func setupFrameForKind() {
    guard let scrollView else { return }
    let h = configuration.expandedHeight
    let safePad = footerSafePadding(for: scrollView)
    switch kind {
    case .pullToRefresh:
      frame = CGRect(
        x: 0,
        y: -h,
        width: scrollView.bounds.width,
        height: h
      )
    case .loadMore:
      let contentH = max(scrollView.contentSize.height, scrollView.bounds.height)
      frame = CGRect(
        x: 0,
        y: contentH,
        width: scrollView.bounds.width,
        height: h + safePad
      )
    }
  }

  private func footerSafePadding(for scrollView: UIScrollView) -> CGFloat {
    configuration.footerSafeAreaPadding + scrollView.safeAreaInsets.bottom
  }

  // MARK: - KVO

  private func startObserving() {
    guard let scrollView else { return }
    scrollOffsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
      self?.scrollViewDidScroll(sv)
    }
    panGestureObservation = scrollView.panGestureRecognizer.observe(\.state, options: [.new]) { [weak self] gesture, _ in
      self?.panGestureStateChanged(gesture.state)
    }
    contentSizeObservation = scrollView.observe(\.contentSize, options: [.new]) { [weak self] sv, _ in
      self?.scrollViewContentSizeDidChange(sv)
    }
    boundsObservation = scrollView.observe(\.bounds, options: [.new]) { [weak self] sv, _ in
      self?.scrollViewBoundsDidChange(sv)
    }
    contentInsetObservation = scrollView.observe(\.contentInset, options: [.new]) { [weak self] sv, _ in
      self?.scrollViewContentInsetDidChange(sv)
    }
  }

  private func stopObserving() {
    scrollOffsetObservation?.invalidate()
    scrollOffsetObservation = nil
    panGestureObservation?.invalidate()
    panGestureObservation = nil
    contentSizeObservation?.invalidate()
    contentSizeObservation = nil
    boundsObservation?.invalidate()
    boundsObservation = nil
    contentInsetObservation?.invalidate()
    contentInsetObservation = nil
  }

  // MARK: - Scroll handling

  private func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard !isUpdatingInset else { return }
    switch kind {
    case .pullToRefresh:
      handlePullToRefreshScroll(scrollView)
    case .loadMore:
      updateLoadMoreFrame(scrollView)
      updateFooterVisibility(for: scrollView)
      handleLoadMoreScroll(scrollView)
    }
  }

  private func scrollViewContentSizeDidChange(_ scrollView: UIScrollView) {
    if kind == .loadMore {
      updateLoadMoreFrame(scrollView)
      updateFooterVisibility(for: scrollView)
    }
  }

  private func scrollViewBoundsDidChange(_ scrollView: UIScrollView) {
    setupFrameForKind()
    if kind == .loadMore {
      updateFooterVisibility(for: scrollView)
    }
  }

  private func scrollViewContentInsetDidChange(_ scrollView: UIScrollView) {
    syncBaselinesFromScrollViewIfSafe(scrollView)
  }

  private func syncBaselinesFromScrollViewIfSafe(_ scrollView: UIScrollView) {
    guard !isUpdatingInset else { return }
    guard !isAnimatingCollapse else { return }
    if kind == .pullToRefresh {
      switch state {
      case .refreshing, .triggered, .finished, .listEmpty, .failed:
        return
      default:
        break
      }
    }
    captureScrollViewBaselines(scrollView)
  }

  private func handlePullToRefreshScroll(_ scrollView: UIScrollView) {
    guard isEnabled else { return }
    guard !isAnimatingCollapse else { return }

    let insetTop = baselineContentInset.top
    let offsetY = scrollView.contentOffset.y

    if state == .refreshing { return }

    switch state {
    case .noMoreData, .finished, .listEmpty:
      return
    case .failed:
      return
    default:
      break
    }

    let pullDistance = -(offsetY + insetTop)

    if pullDistance <= 0 {
      if state != .idle {
        transition(to: .idle)
      }
      currentPullProgress = 0
      contentView.refreshControl(self, didUpdatePullProgress: 0)
      return
    }

    let progress = min(1, pullDistance / configuration.triggerThreshold)
    currentPullProgress = progress
    if progress >= 1 {
      if state != .triggered {
        transition(to: .triggered)
      }
    } else {
      transition(to: .pulling(progress: progress))
    }
    contentView.refreshControl(self, didUpdatePullProgress: progress)
  }

  private func handleLoadMoreScroll(_ scrollView: UIScrollView) {
    guard isEnabled else { return }
    guard state == .idle else { return }
    guard !isFooterHiddenForShortContent(scrollView) else { return }

    let contentH = scrollView.contentSize.height
    let visibleH = scrollView.bounds.height
      - scrollView.adjustedContentInset.top
      - scrollView.adjustedContentInset.bottom

    guard contentH > visibleH else { return }

    let visibleBottom = scrollView.contentOffset.y
      + scrollView.bounds.height
      - scrollView.adjustedContentInset.bottom

    if visibleBottom >= contentH - configuration.triggerThreshold {
      transition(to: .refreshing)
      markLoadingStart()
      fireAction()
    }
  }

  private func updateLoadMoreFrame(_ scrollView: UIScrollView) {
    guard kind == .loadMore else { return }
    let contentH = scrollView.contentSize.height
    let safePad = footerSafePadding(for: scrollView)
    var f = frame
    let newY = max(contentH, scrollView.bounds.height)
    let newH = configuration.expandedHeight + safePad
    if f.origin.y != newY || f.size.width != scrollView.bounds.width || f.size.height != newH {
      f.origin.y = newY
      f.size.width = scrollView.bounds.width
      f.size.height = newH
      frame = f
    }
  }

  private func isFooterHiddenForShortContent(_ scrollView: UIScrollView) -> Bool {
    guard kind == .loadMore else { return false }
    guard configuration.autohidesFooterWhenNotScrollable else { return false }
    let contentH = scrollView.contentSize.height
    let visibleH = scrollView.bounds.height
      - scrollView.adjustedContentInset.top
      - scrollView.adjustedContentInset.bottom
    return contentH <= visibleH + 0.5
  }

  private func updateFooterVisibility(for scrollView: UIScrollView) {
    guard kind == .loadMore else { return }
    let hidden = isFooterHiddenForShortContent(scrollView)
    isHidden = hidden
    isUserInteractionEnabled = !hidden
  }

  private func panGestureStateChanged(_ gestureState: UIGestureRecognizer.State) {
    guard kind == .pullToRefresh else { return }
    guard isEnabled else { return }
    guard gestureState == .ended || gestureState == .cancelled else { return }

    if state == .triggered {
      guard let scrollView else { return }
      scrollView.fk_resetLoadMoreAfterPullToRefresh()
      transition(to: .refreshing)
      markLoadingStart()
      if configuration.isSilentRefresh {
        alpha = 0
        isUserInteractionEnabled = false
        fireAction()
        return
      }
      alpha = 1
      isUserInteractionEnabled = true
      if configuration.shouldKeepExpandedWhileRefreshing {
        expandScrollView(scrollView)
      }
      fireAction()
    } else if case .pulling = state {
      transition(to: .idle)
      currentPullProgress = 0
    }
  }

  // MARK: - State transitions

  private func transition(to newState: FKRefreshState) {
    state = newState
  }

  private func handleStateTransition(from previous: FKRefreshState, to current: FKRefreshState) {
    if case .triggered = current, case .triggered = previous {} else if current == .triggered {
      hapticGenerator?.impactOccurred()
      hapticGenerator?.prepare()
    }
    contentView.refreshControl(self, didTransitionTo: current, from: previous)
    onStateChanged?(self, current)
    delegate?.refreshControl(self, didChange: current, from: previous)
  }

  // MARK: - Timing helpers

  private func markLoadingStart() {
    loadingStartedAt = Date()
  }

  private func runMinimumVisibilityIfNeeded(completion: @escaping () -> Void) {
    pendingEndWorkItem?.cancel()
    let minV = configuration.minimumLoadingVisibilityDuration
    guard minV > 0, let started = loadingStartedAt else {
      completion()
      return
    }
    let elapsed = Date().timeIntervalSince(started)
    if elapsed >= minV {
      completion()
      return
    }
    let work = DispatchWorkItem { [weak self] in
      self?.pendingEndWorkItem = nil
      completion()
    }
    pendingEndWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + (minV - elapsed), execute: work)
  }

  // MARK: - Inset management (header only)

  private func expandScrollView(_ scrollView: UIScrollView) {
    guard kind == .pullToRefresh else { return }
    let expandedTop = baselineContentInset.top + configuration.expandedHeight
    guard scrollView.contentInset.top < expandedTop - 0.5 else { return }
    isAnimatingCollapse = false
    isUpdatingInset = true
    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
      var inset = scrollView.contentInset
      inset.top = expandedTop
      scrollView.contentInset = inset
      var vi = scrollView.verticalScrollIndicatorInsets
      vi.top = self.baselineVerticalIndicatorInsets.top + self.configuration.expandedHeight
      scrollView.verticalScrollIndicatorInsets = vi
    } completion: { [weak self] _ in
      self?.isUpdatingInset = false
    }
  }

  private func collapseScrollView(animated: Bool) {
    guard kind == .pullToRefresh else { return }
    guard let scrollView else { return }
    isAnimatingCollapse = true
    let stateBeforeCollapse = state
    let restore = { [weak self] in
      guard let self else { return }
      self.isUpdatingInset = true
      var inset = scrollView.contentInset
      inset.top = self.baselineContentInset.top
      scrollView.contentInset = inset
      scrollView.verticalScrollIndicatorInsets = self.baselineVerticalIndicatorInsets
    }
    if animated {
      UIView.animate(
        withDuration: configuration.collapseDuration,
        delay: 0,
        options: [.allowUserInteraction, .beginFromCurrentState],
        animations: restore
      ) { [weak self] _ in
        guard let self else { return }
        self.isUpdatingInset = false
        self.isAnimatingCollapse = false
        self.applyPostCollapseHeaderState(from: stateBeforeCollapse)
      }
    } else {
      restore()
      isUpdatingInset = false
      isAnimatingCollapse = false
      applyPostCollapseHeaderState(from: stateBeforeCollapse)
    }
  }

  private func applyPostCollapseHeaderState(from stateBeforeCollapse: FKRefreshState) {
    switch stateBeforeCollapse {
    case .finished, .failed, .listEmpty:
      transition(to: .idle)
      currentPullProgress = 0
    default:
      break
    }
  }

  private func scheduleCollapse(delay: TimeInterval? = nil) {
    let hold = delay ?? configuration.finishedHoldDuration
    DispatchQueue.main.asyncAfter(deadline: .now() + hold) { [weak self] in
      guard let self, self.state != .refreshing else { return }
      self.collapseScrollView(animated: true)
    }
  }

  private func scheduleFooterCompletion() {
    let hold = configuration.finishedHoldDuration
    DispatchQueue.main.asyncAfter(deadline: .now() + hold) { [weak self] in
      guard let self, self.state != .refreshing else { return }
      self.applyFooterIdleTransitionIfNeeded()
    }
  }

  private func applyFooterIdleTransitionIfNeeded() {
    let snapshot = state
    switch snapshot {
    case .finished, .failed, .listEmpty:
      transition(to: .idle)
    default:
      break
    }
  }

  // MARK: - Action

  private func fireAction() {
    actionHandler?()
  }

  // MARK: - Content view embedding

  private func embedContentView(_ view: FKRefreshContentView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    wireRetryTapIfNeeded(view)
  }

  private func wireRetryTapIfNeeded(_ view: FKRefreshContentView) {
    guard let v = view as? FKDefaultRefreshContentView else { return }
    v.onRetryTap = { [weak self] in
      self?.retryAfterFailure()
    }
  }

  // MARK: - Configuration

  private func applyConfiguration() {
    backgroundColor = configuration.backgroundColor
    if configuration.isHapticFeedbackEnabled, hapticGenerator == nil {
      hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
      hapticGenerator?.prepare()
    } else if !configuration.isHapticFeedbackEnabled {
      hapticGenerator = nil
    }
    setupFrameForKind()
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    guard let scrollView else { return }
    var f = frame
    f.size.width = scrollView.bounds.width
    if f.size.width != frame.size.width {
      frame = f
    }
  }
}
