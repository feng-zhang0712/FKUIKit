//
// FKBaseViewController.swift
// FKCompositeKit
//

import UIKit

/// A reusable, non-invasive base view controller for large-scale iOS projects.
///
/// The controller standardizes lifecycle orchestration, UI setup entry points, state overlays,
/// keyboard handling, navigation behavior, and lightweight diagnostics hooks.
open class FKBaseViewController: UIViewController {

  // MARK: - Public Types

  /// Defines navigation bar visibility behavior for the controller.
  public enum NavigationBarVisibility {
    case visible
    case hidden
  }

  /// Defines navigation bar visual style.
  public enum NavigationBarStyle {
    case system
    case transparent
    case gradient(colors: [UIColor], locations: [NSNumber]? = nil, startPoint: CGPoint = CGPoint(x: 0.0, y: 0.0), endPoint: CGPoint = CGPoint(x: 1.0, y: 0.0))
  }

  // MARK: - Public Configuration

  /// Controls whether tapping empty space dismisses the keyboard.
  public var dismissKeyboardOnTapEnabled: Bool = true {
    didSet { updateTapToDismissGestureState() }
  }

  /// Controls whether vertical scroll bounce is disabled recursively in view hierarchy.
  public var disableScrollViewBounceByDefault: Bool = true

  /// Controls whether interactive pop gesture should be disabled for this controller.
  public var disablesInteractivePopGesture: Bool = false

  /// Controls navigation bar visibility while this controller is visible.
  public var navigationBarVisibility: NavigationBarVisibility = .visible

  /// Controls navigation bar style while this controller is visible.
  public var navigationBarStyle: NavigationBarStyle = .system

  /// Controls preferred status bar style for this controller.
  public var preferredStatusBarAppearance: UIStatusBarStyle = .default {
    didSet { setNeedsStatusBarAppearanceUpdate() }
  }

  /// Controls whether keyboard notifications should be observed.
  public var keyboardObservationEnabled: Bool = true

  /// Optional analytics and diagnostics hook for page-level events.
  ///
  /// Use this closure to integrate with any tracking system without coupling this class
  /// to a concrete analytics dependency.
  public var logHandler: ((String, [String: String]) -> Void)?

  // MARK: - Private UI State

  private let loadingView = UIActivityIndicatorView(style: .large)
  private let toastLabel = PaddingLabel()
  private let emptyStateView = FKBaseStateView()
  private let errorStateView = FKBaseStateView()
  private var toastDismissWorkItem: DispatchWorkItem?
  private var keyboardObservers: [NSObjectProtocol] = []
  private lazy var tapToDismissGesture: UITapGestureRecognizer = {
    let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismissKeyboard))
    gesture.cancelsTouchesInView = false
    return gesture
  }()
  private var hasPerformedBaseSetup = false

  // MARK: - Init

  public init() {
    super.init(nibName: nil, bundle: nil)
  }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: - Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()
    performBaseSetupIfNeeded()
    setupUI()
    setupConstraints()
    setupBindings()
    applyDefaultScrollBouncePolicyIfNeeded()
    logLifecycleEvent("viewDidLoad")
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    applyNavigationConfiguration()
    logLifecycleEvent("viewWillAppear")
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startKeyboardObservationIfNeeded()
    logLifecycleEvent("viewDidAppear")
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopKeyboardObservationIfNeeded()
    logLifecycleEvent("viewWillDisappear")
  }

  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    logLifecycleEvent("viewDidDisappear")
  }

  open override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    // Keep state overlays pinned to latest safe-area geometry.
    view.setNeedsLayout()
  }

  deinit {}

  // MARK: - Overridable Entry Points

  /// Builds subviews and configures view hierarchy.
  ///
  /// Subclasses should override this method and keep heavy work out of it.
  open func setupUI() {}

  /// Activates Auto Layout constraints.
  ///
  /// Subclasses should override this method and constrain views created in `setupUI()`.
  open func setupConstraints() {}

  /// Binds view model, events, and async data requests.
  ///
  /// Subclasses should override this method for business-level bindings.
  open func setupBindings() {}

  /// Receives keyboard frame updates.
  ///
  /// - Parameters:
  ///   - frame: Keyboard end frame in the current window coordinate system.
  ///   - duration: Animation duration from keyboard notification.
  ///   - curve: Animation curve from keyboard notification.
  open func keyboardWillChange(to frame: CGRect, duration: TimeInterval, curve: UIView.AnimationCurve) {}

  /// Receives keyboard hidden events.
  ///
  /// - Parameters:
  ///   - duration: Animation duration from keyboard notification.
  ///   - curve: Animation curve from keyboard notification.
  open func keyboardWillHide(duration: TimeInterval, curve: UIView.AnimationCurve) {}

  /// Returns supported interface orientations for this controller.
  open var allowedInterfaceOrientations: UIInterfaceOrientationMask {
    .portrait
  }

  /// Returns preferred orientation when this controller is first presented.
  open var preferredInitialOrientation: UIInterfaceOrientation {
    .portrait
  }

  open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    allowedInterfaceOrientations
  }

  open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    preferredInitialOrientation
  }

  open override var preferredStatusBarStyle: UIStatusBarStyle {
    preferredStatusBarAppearance
  }

  // MARK: - Public UI Tools

  /// Shows a centered loading indicator and hides empty/error overlays.
  public func showLoading() {
    hideEmptyView()
    hideErrorView()
    loadingView.startAnimating()
    loadingView.isHidden = false
  }

  /// Hides the loading indicator.
  public func hideLoading() {
    loadingView.stopAnimating()
    loadingView.isHidden = true
  }

  /// Shows a full-screen empty state overlay.
  ///
  /// - Parameter message: User-facing message for empty content.
  public func showEmptyView(message: String = "No content available.") {
    hideLoading()
    hideErrorView()
    emptyStateView.messageLabel.text = message
    emptyStateView.isHidden = false
  }

  /// Hides the empty state overlay.
  public func hideEmptyView() {
    emptyStateView.isHidden = true
  }

  /// Shows a full-screen error state overlay.
  ///
  /// - Parameters:
  ///   - message: User-facing error message.
  ///   - retryTitle: Optional retry button title.
  ///   - retryHandler: Optional retry callback.
  public func showErrorView(
    message: String = "Something went wrong.",
    retryTitle: String? = nil,
    retryHandler: (() -> Void)? = nil
  ) {
    hideLoading()
    hideEmptyView()
    errorStateView.messageLabel.text = message
    errorStateView.button.setTitle(retryTitle, for: .normal)
    errorStateView.actionHandler = retryHandler
    errorStateView.button.isHidden = (retryTitle == nil || retryHandler == nil)
    errorStateView.isHidden = false
  }

  /// Hides the error state overlay.
  public func hideErrorView() {
    errorStateView.isHidden = true
    errorStateView.actionHandler = nil
  }

  /// Shows a short-lived toast message near the bottom safe area.
  ///
  /// - Parameter message: Message text shown to user.
  public func showToast(_ message: String) {
    toastDismissWorkItem?.cancel()
    toastLabel.text = message
    toastLabel.alpha = 0.0
    toastLabel.isHidden = false
    view.bringSubviewToFront(toastLabel)

    UIView.animate(withDuration: UIConstants.toastFadeDuration) {
      self.toastLabel.alpha = 1.0
    }

    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      UIView.animate(withDuration: UIConstants.toastFadeDuration, animations: {
        self.toastLabel.alpha = 0.0
      }, completion: { _ in
        self.toastLabel.isHidden = true
      })
    }

    toastDismissWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.toastDisplayDuration, execute: workItem)
  }

  /// Configures a custom back button item.
  ///
  /// - Parameters:
  ///   - image: Optional button image.
  ///   - title: Optional button title.
  ///   - tintColor: Optional tint color.
  public func configureBackButton(image: UIImage? = nil, title: String? = nil, tintColor: UIColor? = nil) {
    let button = UIButton(type: .system)
    let symbolImage = image ?? UIImage(systemName: "chevron.backward")
    button.setImage(symbolImage, for: .normal)
    button.setTitle(title, for: .normal)
    button.tintColor = tintColor ?? view.tintColor
    button.setTitleColor(tintColor ?? view.tintColor, for: .normal)
    button.contentEdgeInsets = UIConstants.backButtonContentInsets
    button.addTarget(self, action: #selector(handleBackButtonTapped), for: .touchUpInside)
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
  }

  /// Hides keyboard if current first responder exists.
  public func dismissKeyboard() {
    view.endEditing(true)
  }

  // MARK: - Private Setup

  private func performBaseSetupIfNeeded() {
    guard !hasPerformedBaseSetup else { return }
    hasPerformedBaseSetup = true

    view.backgroundColor = .systemBackground
    setupLoadingView()
    setupStateViews()
    setupToastView()
    updateTapToDismissGestureState()
  }

  private func setupLoadingView() {
    loadingView.translatesAutoresizingMaskIntoConstraints = false
    loadingView.hidesWhenStopped = true
    loadingView.isHidden = true
    view.addSubview(loadingView)
    NSLayoutConstraint.activate([
      loadingView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      loadingView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
  }

  private func setupStateViews() {
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false
    emptyStateView.isHidden = true
    view.addSubview(emptyStateView)

    errorStateView.translatesAutoresizingMaskIntoConstraints = false
    errorStateView.isHidden = true
    view.addSubview(errorStateView)

    NSLayoutConstraint.activate([
      emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      errorStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      errorStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      errorStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      errorStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  private func setupToastView() {
    toastLabel.translatesAutoresizingMaskIntoConstraints = false
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(UIConstants.toastBackgroundOpacity)
    toastLabel.textColor = .white
    toastLabel.font = .preferredFont(forTextStyle: .footnote)
    toastLabel.numberOfLines = 0
    toastLabel.textAlignment = .center
    toastLabel.layer.cornerRadius = UIConstants.toastCornerRadius
    toastLabel.layer.masksToBounds = true
    toastLabel.alpha = 0.0
    toastLabel.isHidden = true
    view.addSubview(toastLabel)

    NSLayoutConstraint.activate([
      toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: UIConstants.toastHorizontalMargin),
      toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -UIConstants.toastHorizontalMargin),
      toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UIConstants.toastBottomMargin),
      toastLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: UIConstants.toastMaxWidthRatio),
    ])
  }

  private func applyDefaultScrollBouncePolicyIfNeeded() {
    guard disableScrollViewBounceByDefault else { return }
    view.fk_applyBounce(enabled: false)
  }

  private func applyNavigationConfiguration() {
    navigationController?.setNavigationBarHidden(navigationBarVisibility == .hidden, animated: false)
    applyNavigationBarStyle()
  }

  private func applyNavigationBarStyle() {
    guard let navigationController else { return }
    switch navigationBarStyle {
    case .system:
      // Non-invasive default:
      // Do not override global/project navigation bar appearance unless explicitly requested.
      return
    case .transparent:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      navigationController.navigationBar.standardAppearance = appearance
      navigationController.navigationBar.scrollEdgeAppearance = appearance
      navigationController.navigationBar.compactAppearance = appearance
    case let .gradient(colors, locations, startPoint, endPoint):
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      appearance.backgroundImage = FKGradientImageFactory.makeGradientImage(
        colors: colors,
        locations: locations,
        size: UIConstants.navigationBarGradientSize,
        startPoint: startPoint,
        endPoint: endPoint
      )
      navigationController.navigationBar.standardAppearance = appearance
      navigationController.navigationBar.scrollEdgeAppearance = appearance
      navigationController.navigationBar.compactAppearance = appearance
    }
  }

  private func updateTapToDismissGestureState() {
    if dismissKeyboardOnTapEnabled {
      if tapToDismissGesture.view == nil {
        view.addGestureRecognizer(tapToDismissGesture)
      }
    } else {
      if tapToDismissGesture.view != nil {
        view.removeGestureRecognizer(tapToDismissGesture)
      }
    }
  }

  // MARK: - Keyboard Observation

  private func startKeyboardObservationIfNeeded() {
    guard keyboardObservationEnabled, keyboardObservers.isEmpty else { return }

    let center = NotificationCenter.default
    let willChange = center.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard
        let self,
        let userInfo = notification.userInfo,
        let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
      else {
        return
      }
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
      self.keyboardWillChange(to: frame, duration: duration, curve: curve)
    }

    let willHide = center.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let userInfo = notification.userInfo
      let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
      self.keyboardWillHide(duration: duration, curve: curve)
    }

    keyboardObservers = [willChange, willHide]
  }

  private func stopKeyboardObservationIfNeeded() {
    guard !keyboardObservers.isEmpty else { return }
    let center = NotificationCenter.default
    keyboardObservers.forEach(center.removeObserver)
    keyboardObservers.removeAll()
  }

  // Keyboard notifications are parsed inside the observer closures to avoid passing `Notification`
  // across isolation boundaries under strict concurrency checking.

  private func logLifecycleEvent(_ event: String) {
    logHandler?(event, ["controller": String(describing: type(of: self))])
  }

  // MARK: - Actions

  @objc private func handleTapToDismissKeyboard() {
    dismissKeyboard()
  }

  @objc private func handleBackButtonTapped() {
    if let navigationController, navigationController.viewControllers.first != self {
      navigationController.popViewController(animated: true)
    } else {
      dismiss(animated: true)
    }
  }
}

// MARK: - Internal UI Types

private enum UIConstants {
  static let toastDisplayDuration: TimeInterval = 1.8
  static let toastFadeDuration: TimeInterval = 0.22
  static let toastCornerRadius: CGFloat = 8.0
  static let toastHorizontalMargin: CGFloat = 24.0
  static let toastBottomMargin: CGFloat = 20.0
  static let toastMaxWidthRatio: CGFloat = 0.86
  static let toastBackgroundOpacity: CGFloat = 0.82
  static let navigationBarGradientSize = CGSize(width: 4.0, height: 88.0)
  static let stateViewHorizontalInset: CGFloat = 32.0
  static let stateViewSpacing: CGFloat = 12.0
  static let stateButtonTopSpacing: CGFloat = 8.0
  static let labelHorizontalPadding: CGFloat = 12.0
  static let labelVerticalPadding: CGFloat = 8.0
  static let backButtonContentInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: 4.0, right: 0.0)
}

/// A reusable view that displays simple state content and optional action button.
private final class FKBaseStateView: UIView {
  let stackView = UIStackView()
  let messageLabel = UILabel()
  let button = UIButton(type: .system)
  var actionHandler: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    backgroundColor = .clear

    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = UIConstants.stateViewSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)

    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    messageLabel.textColor = .secondaryLabel
    messageLabel.font = .preferredFont(forTextStyle: .body)
    messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

    button.addTarget(self, action: #selector(handleButtonTapped), for: .touchUpInside)
    button.isHidden = true

    stackView.addArrangedSubview(messageLabel)
    stackView.addArrangedSubview(button)
    stackView.setCustomSpacing(UIConstants.stateButtonTopSpacing, after: messageLabel)

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UIConstants.stateViewHorizontalInset),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UIConstants.stateViewHorizontalInset),
    ])
  }

  @objc private func handleButtonTapped() {
    actionHandler?()
  }
}

/// A label with content insets for toast presentation.
private final class PaddingLabel: UILabel {
  private let contentInsets = UIEdgeInsets(
    top: UIConstants.labelVerticalPadding,
    left: UIConstants.labelHorizontalPadding,
    bottom: UIConstants.labelVerticalPadding,
    right: UIConstants.labelHorizontalPadding
  )

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: contentInsets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(
      width: size.width + contentInsets.left + contentInsets.right,
      height: size.height + contentInsets.top + contentInsets.bottom
    )
  }
}

/// Utility factory that builds gradient images for navigation bar backgrounds.
private enum FKGradientImageFactory {
  static func makeGradientImage(
    colors: [UIColor],
    locations: [NSNumber]?,
    size: CGSize,
    startPoint: CGPoint,
    endPoint: CGPoint
  ) -> UIImage? {
    guard size.width > 0.0, size.height > 0.0, !colors.isEmpty else { return nil }

    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      let layer = CAGradientLayer()
      layer.frame = CGRect(origin: .zero, size: size)
      layer.colors = colors.map(\.cgColor)
      layer.locations = locations
      layer.startPoint = startPoint
      layer.endPoint = endPoint
      layer.render(in: context.cgContext)
    }
  }
}

private extension UIView {
  /// Recursively applies bounce behavior to all scroll views in the subtree.
  func fk_applyBounce(enabled: Bool) {
    if let scrollView = self as? UIScrollView {
      scrollView.bounces = enabled
      scrollView.alwaysBounceVertical = enabled
      scrollView.alwaysBounceHorizontal = enabled
    }
    subviews.forEach { $0.fk_applyBounce(enabled: enabled) }
  }
}
