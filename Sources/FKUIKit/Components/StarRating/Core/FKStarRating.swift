//
// FKStarRating.swift
//
// Pure UIKit star rating component.
//

import UIKit

/// A lightweight UIKit-native rating component for enterprise-scale iOS projects.
///
/// `FKStarRating` supports full star, half star, and precise decimal score modes.
/// It is designed for list reuse scenarios, supports both programmatic and Interface Builder setup,
/// and avoids expensive drawing by using reusable image layers.
@MainActor
@IBDesignable
public final class FKStarRating: UIControl {
  /// App-wide default configuration.
  public static var defaultConfiguration: FKStarRatingConfiguration {
    get { FKStarRatingManager.shared.defaultConfiguration }
    set { FKStarRatingManager.shared.defaultConfiguration = newValue }
  }

  /// Full configuration payload for this instance.
  public var configuration: FKStarRatingConfiguration {
    didSet {
      guard !isApplyingConfigurationUpdate else { return }
      isApplyingConfigurationUpdate = true
      defer { isApplyingConfigurationUpdate = false }
      configuration = normalizedConfiguration(configuration)
      rebuildStarViewsIfNeeded()
      applyConfigurationToViews()
      setRating(rating, animated: false, notify: false)
    }
  }

  /// Current rating value. Range is clamped by `minimumRating...maximumRating`.
  public private(set) var rating: CGFloat = 0

  /// Realtime callback emitted while value is changing.
  public var onRatingChanged: ((CGFloat) -> Void)?
  /// Final callback emitted when an edit gesture ends.
  public var onRatingCommit: ((CGFloat) -> Void)?

  private let stackView = UIStackView()
  private var starViews: [FKStarRatingStarView] = []
  private var didSetupViews = false
  private var isCommittingFromGesture = false
  private var isApplyingConfigurationUpdate = false
  private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
  private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))

  /// Creates rating view with default global configuration.
  public override init(frame: CGRect) {
    configuration = FKStarRating.defaultConfiguration
    super.init(frame: frame)
    commonInit()
  }

  /// Creates rating view from storyboard/xib.
  public required init?(coder: NSCoder) {
    configuration = FKStarRating.defaultConfiguration
    super.init(coder: coder)
    commonInit()
  }

  /// Returns intrinsic size based on star count, size, and spacing.
  public override var intrinsicContentSize: CGSize {
    let width = CGFloat(configuration.starCount) * configuration.starSize.width
      + CGFloat(max(0, configuration.starCount - 1)) * configuration.starSpacing
    return CGSize(width: width, height: configuration.starSize.height)
  }

  /// One-line API to update full configuration.
  public func configure(_ configuration: FKStarRatingConfiguration) {
    self.configuration = configuration
  }

  /// One-line builder API to mutate configuration.
  public func configure(_ updates: (inout FKStarRatingConfiguration) -> Void) {
    var copy = configuration
    updates(&copy)
    configuration = copy
  }

  /// Sets rating and refreshes UI immediately.
  ///
  /// - Parameters:
  ///   - value: Target rating.
  ///   - animated: Whether visual update should animate.
  ///   - notify: Whether callbacks and control events should be emitted.
  public func setRating(_ value: CGFloat, animated: Bool = false, notify: Bool = true) {
    let clamped = snapAndClamp(value)
    let changed = abs(clamped - rating) > 0.0001
    guard changed || (notify && isCommittingFromGesture) else { return }
    rating = clamped
    if changed {
      applyFill(animated: animated)
    }
    guard notify else { return }
    if changed {
      onRatingChanged?(rating)
      sendActions(for: .valueChanged)
    }
    if isCommittingFromGesture {
      onRatingCommit?(rating)
      sendActions(for: .editingDidEnd)
    }
  }

  /// Resets rating to `minimumRating`.
  public func resetRating() {
    setRating(configuration.minimumRating, animated: false, notify: true)
  }

  /// Restores this instance style to global defaults.
  public func resetStyle() {
    configuration = FKStarRating.defaultConfiguration
  }

  /// API for reusable cell workflows to clear volatile state.
  ///
  /// Use this in `prepareForReuse()` for list cells.
  public func prepareForReuse() {
    onRatingChanged = nil
    onRatingCommit = nil
    isCommittingFromGesture = false
    setRating(configuration.minimumRating, animated: false, notify: false)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    updateMaskFrames()
  }

  public override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    applyConfigurationToViews()
    applyFill(animated: false)
  }
}

private extension FKStarRating {
  func commonInit() {
    configuration = normalizedConfiguration(configuration)
    setupViewsIfNeeded()
    rebuildStarViewsIfNeeded()
    applyConfigurationToViews()
    installGestures()
    setRating(configuration.minimumRating, animated: false, notify: false)
  }

  func setupViewsIfNeeded() {
    guard !didSetupViews else { return }
    didSetupViews = true
    clipsToBounds = false
    stackView.axis = .horizontal
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  func rebuildStarViewsIfNeeded() {
    guard starViews.count != configuration.starCount else { return }
    starViews.forEach { $0.removeFromSuperview() }
    starViews.removeAll(keepingCapacity: true)
    for _ in 0 ..< configuration.starCount {
      let starView = FKStarRatingStarView()
      stackView.addArrangedSubview(starView)
      starViews.append(starView)
    }
    invalidateIntrinsicContentSize()
  }

  func applyConfigurationToViews() {
    isUserInteractionEnabled = configuration.isEditable
    stackView.spacing = configuration.starSpacing
    starViews.forEach { star in
      star.applyResources(
        selectedImage: configuration.selectedImage,
        unselectedImage: configuration.unselectedImage,
        halfImage: configuration.halfImage,
        selectedTintColor: configuration.selectedColor,
        unselectedTintColor: configuration.unselectedColor,
        renderMode: configuration.renderMode
      )
      star.applyStyle(configuration.starStyle)
    }
    applyFill(animated: false)
  }

  func normalizedConfiguration(_ source: FKStarRatingConfiguration) -> FKStarRatingConfiguration {
    var configuration = source
    configuration.starCount = max(1, min(10, configuration.starCount))
    configuration.starSize.width = max(1, configuration.starSize.width)
    configuration.starSize.height = max(1, configuration.starSize.height)
    configuration.starSpacing = max(0, configuration.starSpacing)
    configuration.minimumRating = max(0, min(configuration.minimumRating, CGFloat(configuration.starCount)))
    configuration.maximumRating = max(
      configuration.minimumRating,
      min(CGFloat(configuration.starCount), configuration.maximumRating)
    )
    return configuration
  }

  func applyFill(animated: Bool) {
    let updates = { [self] in
      for (index, starView) in starViews.enumerated() {
        let starStart = CGFloat(index)
        let fill = max(0, min(1, rating - starStart))
        starView.updateFill(fill)
      }
    }

    if animated {
      UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: updates)
    } else {
      updates()
    }
  }

  func updateMaskFrames() {
    for (index, starView) in starViews.enumerated() {
      let fill = max(0, min(1, rating - CGFloat(index)))
      starView.updateFill(fill)
    }
  }

  func snapAndClamp(_ raw: CGFloat) -> CGFloat {
    let clamped = max(configuration.minimumRating, min(configuration.maximumRating, raw))
    let step = configuration.mode.step
    let snapped = (clamped / step).rounded() * step
    return max(configuration.minimumRating, min(configuration.maximumRating, snapped))
  }

  func installGestures() {
    tapGesture.cancelsTouchesInView = false
    panGesture.cancelsTouchesInView = false
    addGestureRecognizer(tapGesture)
    addGestureRecognizer(panGesture)
  }

  @objc
  func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
    guard configuration.isEditable else { return }
    let value = ratingValue(at: recognizer.location(in: self))
    isCommittingFromGesture = true
    setRating(value, animated: false, notify: true)
    isCommittingFromGesture = false
  }

  @objc
  func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.isEditable else { return }
    guard configuration.allowsContinuousPan else { return }
    let value = ratingValue(at: recognizer.location(in: self))
    switch recognizer.state {
    case .began, .changed:
      isCommittingFromGesture = false
      setRating(value, animated: false, notify: true)
      sendActions(for: .editingChanged)
    case .ended, .cancelled, .failed:
      isCommittingFromGesture = true
      setRating(value, animated: false, notify: true)
      isCommittingFromGesture = false
    default:
      break
    }
  }

  func ratingValue(at point: CGPoint) -> CGFloat {
    guard bounds.width > 0 else { return configuration.minimumRating }
    let clampedX = max(0, min(bounds.width, point.x))
    let progress = clampedX / bounds.width
    let rawValue = progress * CGFloat(configuration.starCount)
    return snapAndClamp(rawValue)
  }
}
