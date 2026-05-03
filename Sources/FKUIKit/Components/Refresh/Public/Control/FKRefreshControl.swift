import UIKit

/// Identifies whether a control acts as a pull header or a load-more footer.
public enum FKRefreshKind: Sendable {
  case pullToRefresh
  case loadMore
}

/// UIKit refresh control: manages overscroll detection, insets, state, and callbacks.
///
/// Attach only through ``UIScrollView`` helpers (``UIScrollView/fk_addPullToRefresh(configuration:action:)`` /
/// ``UIScrollView/fk_addLoadMore(configuration:action:)``). Do not insert this view into the hierarchy yourself.
@MainActor
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
  /// Async callback alternative to `actionHandler`.
  public var asyncActionHandler: FKRefreshAsyncHandler?
  /// Context-aware callback with token/source for race-safe integrations.
  public var contextActionHandler: FKRefreshActionHandler?
  /// Context-aware async callback with token/source for race-safe integrations.
  public var contextAsyncActionHandler: FKRefreshContextAsyncHandler?

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
  nonisolated(unsafe) private var scrollOffsetObservation: NSKeyValueObservation?
  nonisolated(unsafe) private var panGestureObservation: NSKeyValueObservation?
  nonisolated(unsafe) private var contentSizeObservation: NSKeyValueObservation?
  nonisolated(unsafe) private var contentInsetObservation: NSKeyValueObservation?
  nonisolated(unsafe) private var boundsObservation: NSKeyValueObservation?

  /// Baseline insets captured while the control is not mutating `contentInset` / indicators.
  private var baselineContentInset: UIEdgeInsets = .zero
  private var baselineVerticalIndicatorInsets: UIEdgeInsets = .zero

  private var isAnimatingCollapse = false
  private var hapticGenerator: UIImpactFeedbackGenerator?
  /// Prevents re-entrant KVO when we mutate `contentInset` ourselves.
  private var isUpdatingInset = false
  private var loadingStartedAt: Date?
  private var pendingEndWorkItem: DispatchWorkItem?
  private var asyncTask: Task<Void, Never>?
  private weak var coordinator: FKRefreshCoordinator?
  private var clock: FKRefreshClock
  private var currentActionToken: UInt64?
  private var nextActionToken: UInt64 = 0

  /// After an automatic bottom load fires, stays `false` until the user scrolls clearly above the trigger band (avoids failure → idle → immediate re-fire while dragging near the bottom).
  private var loadMoreAutoTriggerArmed = true

  // MARK: - Init

  public init(
    kind: FKRefreshKind,
    configuration: FKRefreshConfiguration = .default,
    contentView: FKRefreshContentView? = nil,
    action: FKVoidHandler? = nil,
    asyncAction: FKRefreshAsyncHandler? = nil,
    clock: FKRefreshClock = FKSystemRefreshClock()
  ) {
    self.kind = kind
    self.configuration = configuration
    let cv = contentView ?? FKDefaultRefreshContentView()
    self.contentView = cv
    self.actionHandler = action
    self.asyncActionHandler = asyncAction
    self.clock = clock
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
    fatalError("FKRefreshControl is not supported from Interface Builder; use the programmatic initializer.")
  }

  deinit {
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
      loadMoreAutoTriggerArmed = true
      updateFooterVisibility(for: scrollView)
    }
  }

  func setCoordinator(_ coordinator: FKRefreshCoordinator?) {
    self.coordinator = coordinator
    coordinator?.register(control: self)
  }

  func detach() {
    if currentActionToken != nil {
      coordinator?.didCancel(kind: kind)
    }
    stopBlockingInteractionIfNeeded()
    coordinator?.unregister(control: self)
    stopObserving()
    pendingEndWorkItem?.cancel()
    pendingEndWorkItem = nil
    asyncTask?.cancel()
    asyncTask = nil
    loadMoreAutoTriggerArmed = true
    removeFromSuperview()
    scrollView = nil
  }

  // MARK: - Public control

  /// Programmatically begin pull-to-refresh or silent refresh.
  public func beginRefreshing(animated: Bool = true, triggerSource: FKRefreshTriggerSource = .programmatic) {
    ensureMain { self.beginRefreshingOnMain(animated: animated, triggerSource: triggerSource) }
  }

  /// Programmatically begin load-more (same semantics as an automatic bottom trigger).
  public func beginLoadingMore(triggerSource: FKRefreshTriggerSource = .programmatic) {
    ensureMain { self.beginLoadingMoreOnMain(triggerSource: triggerSource) }
  }

  /// Successful completion (header or footer).
  public func endRefreshing(token: UInt64? = nil) {
    ensureMain { self.endRefreshingOnMain(outcome: .success, token: token) }
  }

  /// Footer convenience — identical to ``endRefreshing``.
  public func endLoadingMore() {
    endRefreshing()
  }

  /// Header: refresh succeeded but the first page has no rows.
  public func endRefreshingWithEmptyList(token: UInt64? = nil) {
    ensureMain { self.endRefreshingOnMain(outcome: .emptyList, token: token) }
  }

  /// Footer: pagination is exhausted.
  public func endRefreshingWithNoMoreData(token: UInt64? = nil) {
    ensureMain { self.endRefreshingOnMain(outcome: .noMoreData, token: token) }
  }

  /// Any failure path — shows retry affordance on the bundled default footer.
  public func endRefreshingWithError(_ error: Error? = nil, token: UInt64? = nil) {
    ensureMain { self.endRefreshingOnMain(outcome: .failure(error), token: token) }
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

  /// Cancels in-flight async work and optionally resets state to `.idle`.
  public func cancelCurrentAction(resetState: Bool = true) {
    ensureMain { self.cancelCurrentActionOnMain(resetState: resetState) }
  }

  // MARK: - Main queue

  private func ensureMain(_ work: @escaping @MainActor () -> Void) {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        work()
      }
    } else {
      Task { @MainActor in
        work()
      }
    }
  }

  private func beginRefreshingOnMain(animated: Bool, triggerSource: FKRefreshTriggerSource) {
    guard isEnabled else { return }
    guard kind == .pullToRefresh else { return }
    guard state != .refreshing else { return }
    guard state != .loadingMore else { return }
    guard coordinator?.canStart(kind: kind) ?? true else { return }
    guard let scrollView else { return }

    scrollView.fk_resetLoadMoreAfterPullToRefresh()

    if configuration.isSilentRefresh {
      alpha = 0
      isUserInteractionEnabled = false
      transition(to: .refreshing)
      markLoadingStart()
      startBlockingInteractionIfNeeded()
      fireAction(triggerSource: triggerSource)
      return
    }

    alpha = 1
    isUserInteractionEnabled = true
    transition(to: .refreshing)
    markLoadingStart()
    startBlockingInteractionIfNeeded()
    if animated && configuration.shouldKeepExpandedWhileRefreshing {
      expandScrollView(scrollView)
      let targetOffsetY = -(baselineContentInset.top + configuration.expandedHeight)
      if scrollView.contentOffset.y > targetOffsetY {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
          scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: targetOffsetY)
        }
      }
    }
    fireAction(triggerSource: triggerSource)
  }

  private func beginLoadingMoreOnMain(triggerSource: FKRefreshTriggerSource) {
    guard isEnabled else { return }
    guard kind == .loadMore else { return }
    guard state == .idle else { return }
    guard coordinator?.canStart(kind: kind) ?? true else { return }
    guard let scrollView else { return }
    guard !isFooterHiddenForShortContent(scrollView) else { return }
    loadMoreAutoTriggerArmed = false
    transition(to: .loadingMore)
    markLoadingStart()
    fireAction(triggerSource: triggerSource)
  }

  private enum EndOutcome {
    case success
    case emptyList
    case noMoreData
    case failure(Error?)
  }

  private func endRefreshingOnMain(outcome: EndOutcome, token: UInt64?) {
    guard token.map(isCurrentToken) ?? true else { return }
    switch outcome {
    case .success:
      guard state == .refreshing || state == .loadingMore || state == .triggered || state == .readyToRefresh else { return }
      transition(to: .finished)
    case .emptyList:
      guard kind == .pullToRefresh else { return }
      guard state == .refreshing || state == .triggered || state == .readyToRefresh else { return }
      transition(to: .listEmpty)
    case .noMoreData:
      guard kind == .loadMore else { return }
      guard state == .loadingMore || state == .refreshing || state == .triggered || state == .readyToRefresh else { return }
      transition(to: .noMoreData)
    case .failure(let error):
      guard state == .refreshing || state == .loadingMore || state == .triggered || state == .readyToRefresh else { return }
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
      self.finishActionLifecycle()
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
    loadMoreAutoTriggerArmed = true
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
    loadMoreAutoTriggerArmed = false
    transition(to: .loadingMore)
    markLoadingStart()
    fireAction(triggerSource: .retry)
  }

  private func cancelCurrentActionOnMain(resetState: Bool) {
    pendingEndWorkItem?.cancel()
    pendingEndWorkItem = nil
    asyncTask?.cancel()
    asyncTask = nil
    stopBlockingInteractionIfNeeded()
    coordinator?.didCancel(kind: kind)
    currentActionToken = nil
    loadingStartedAt = nil
    if resetState {
      resetToIdleOnMain()
    }
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
      case .refreshing, .loadingMore, .triggered, .readyToRefresh, .finished, .listEmpty, .failed:
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

    if state == .refreshing || state == .loadingMore { return }

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
      if state != .readyToRefresh {
        transition(to: .readyToRefresh)
      }
    } else {
      transition(to: .pulling(progress: progress))
    }
    contentView.refreshControl(self, didUpdatePullProgress: progress)
  }

  private func handleLoadMoreScroll(_ scrollView: UIScrollView) {
    guard isEnabled else { return }
    guard configuration.loadMoreTriggerMode == .automatic else { return }
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

    let preload = max(configuration.loadMorePreloadOffset, configuration.triggerThreshold)
    let triggerLine = contentH - preload
    let releaseSlack = max(CGFloat(24), configuration.triggerThreshold * 0.25)
    if visibleBottom < triggerLine - releaseSlack {
      loadMoreAutoTriggerArmed = true
    }
    guard visibleBottom >= triggerLine else { return }
    guard loadMoreAutoTriggerArmed else { return }
    loadMoreAutoTriggerArmed = false
    transition(to: .loadingMore)
    markLoadingStart()
    fireAction(triggerSource: .userInteraction)
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

    if state == .triggered || state == .readyToRefresh {
      guard coordinator?.canStart(kind: kind) ?? true else {
        transition(to: .idle)
        return
      }
      guard let scrollView else { return }
      scrollView.fk_resetLoadMoreAfterPullToRefresh()
      transition(to: .refreshing)
      markLoadingStart()
      startBlockingInteractionIfNeeded()
      if configuration.isSilentRefresh {
        alpha = 0
        isUserInteractionEnabled = false
        fireAction(triggerSource: .userInteraction)
        return
      }
      alpha = 1
      isUserInteractionEnabled = true
      if configuration.shouldKeepExpandedWhileRefreshing {
        expandScrollView(scrollView)
      }
      fireAction(triggerSource: .userInteraction)
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
    if (current == .triggered || current == .readyToRefresh) && (previous != .triggered && previous != .readyToRefresh) {
      hapticGenerator?.impactOccurred()
      hapticGenerator?.prepare()
    }
    contentView.refreshControl(self, didTransitionTo: current, from: previous)
    announceAccessibilityStateIfNeeded(current)
    onStateChanged?(self, current)
    delegate?.refreshControl(self, didChange: current, from: previous)
  }

  private func announceAccessibilityStateIfNeeded(_ state: FKRefreshState) {
    guard UIAccessibility.isVoiceOverRunning else { return }
    let text = configuration.texts
    let message: String?
    switch state {
    case .refreshing:
      message = text.headerLoading
    case .loadingMore:
      message = text.footerLoading
    case .failed:
      message = kind == .loadMore ? text.footerFailed : text.headerFailed
    case .noMoreData:
      message = text.footerNoMoreData
    default:
      message = nil
    }
    if let message {
      UIAccessibility.post(notification: .announcement, argument: message)
    }
  }

  // MARK: - Timing helpers

  private func markLoadingStart() {
    loadingStartedAt = clock.now()
    nextActionToken &+= 1
    currentActionToken = nextActionToken
    coordinator?.didStart(kind: kind)
  }

  private func isCurrentToken(_ token: UInt64) -> Bool {
    currentActionToken == token
  }

  private func currentContext(source: FKRefreshTriggerSource) -> FKRefreshActionContext? {
    guard let token = currentActionToken else { return nil }
    return FKRefreshActionContext(token: token, kind: kind, source: source, startedAt: loadingStartedAt ?? clock.now())
  }

  private func finishActionLifecycle() {
    stopBlockingInteractionIfNeeded()
    coordinator?.didComplete(kind: kind, isTerminal: true)
    currentActionToken = nil
    loadingStartedAt = nil
  }

  private func startBlockingInteractionIfNeeded() {
    guard configuration.blocksUserInteractionWhileRefreshing, kind == .pullToRefresh else { return }
    scrollView?.isUserInteractionEnabled = false
  }

  private func stopBlockingInteractionIfNeeded() {
    guard configuration.blocksUserInteractionWhileRefreshing, kind == .pullToRefresh else { return }
    scrollView?.isUserInteractionEnabled = true
  }

  private func runMinimumVisibilityIfNeeded(completion: @escaping () -> Void) {
    pendingEndWorkItem?.cancel()
    let minV = configuration.minimumLoadingVisibilityDuration
    guard minV > 0, let started = loadingStartedAt else {
      completion()
      return
    }
    let elapsed = clock.now().timeIntervalSince(started)
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
      guard let self, self.state != .refreshing, self.state != .loadingMore else { return }
      self.collapseScrollView(animated: true)
    }
  }

  private func scheduleFooterCompletion() {
    let hold = configuration.finishedHoldDuration
    DispatchQueue.main.asyncAfter(deadline: .now() + hold) { [weak self] in
      guard let self, self.state != .refreshing, self.state != .loadingMore else { return }
      self.applyFooterIdleTransitionIfNeeded()
    }
  }

  private func applyFooterIdleTransitionIfNeeded() {
    guard kind == .loadMore else { return }
    let snapshot = state
    switch snapshot {
    case .failed:
      return
    case .finished, .listEmpty:
      transition(to: .idle)
      // After a successful footer completion we become `.idle` while `loadMoreAutoTriggerArmed` is still
      // `false` from when loading started. Leaving it false required scrolling upward past the release slack
      // before another automatic load — fine for slow requests, but breaks “stay at the bottom” pagination
      // when work finishes almost instantly. Re-arm here only on this success path; `.failed` keeps the
      // footer non-idle and never reaches this branch.
      loadMoreAutoTriggerArmed = true
    default:
      break
    }
  }

  // MARK: - Action

  private func fireAction(triggerSource: FKRefreshTriggerSource) {
    asyncTask?.cancel()
    let context = currentContext(source: triggerSource)
    actionHandler?()
    if let context {
      contextActionHandler?(context)
    }
    let legacyAsync = asyncActionHandler
    let contextAsync = contextAsyncActionHandler
    guard legacyAsync != nil || contextAsync != nil else { return }
    asyncTask = Task { [weak self] in
      guard let self else { return }
      do {
        if let legacyAsync {
          try await legacyAsync()
        }
        if let context, let contextAsync {
          try await contextAsync(context)
        }
        await MainActor.run {
          guard self.configuration.automaticallyEndsRefreshingOnAsyncCompletion else { return }
          self.finishAsyncActionWithSuccess(token: context?.token)
        }
      } catch {
        await MainActor.run {
          guard self.configuration.automaticallyEndsRefreshingOnAsyncCompletion else { return }
          self.finishAsyncActionWithFailure(error, token: context?.token)
        }
      }
    }
  }

  private func finishAsyncActionWithSuccess(token: UInt64?) {
    let delay = configuration.automaticEndDelay
    if delay <= 0 {
      endRefreshing(token: token)
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      self?.endRefreshing(token: token)
    }
  }

  private func finishAsyncActionWithFailure(_ error: Error, token: UInt64?) {
    let delay = configuration.automaticEndDelay
    if delay <= 0 {
      endRefreshingWithError(error, token: token)
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      self?.endRefreshingWithError(error, token: token)
    }
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
