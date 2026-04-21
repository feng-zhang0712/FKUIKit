//
// FKBaseCollectionViewCell.swift
// FKCompositeKit
//

import UIKit

/// A reusable, extensible base class for `UICollectionViewCell`.
///
/// This class provides a unified initialization flow and extension points for UI setup, style setup,
/// and model binding.
open class FKBaseCollectionViewCell: UICollectionViewCell {

  /// Default reusable identifier derived from class name.
  open class var reuseIdentifier: String {
    String(describing: self)
  }

  /// Main container view used by subclasses to build UI content.
  public let containerView = UIView()

  /// Content insets applied to `containerView` inside `contentView`.
  public var containerInsets: UIEdgeInsets = .zero {
    didSet { updateContainerConstraints() }
  }

  /// Corner radius applied to `containerView`.
  public var cornerRadius: CGFloat = .zero {
    didSet { containerView.layer.cornerRadius = cornerRadius }
  }

  /// Border width applied to `containerView`.
  public var borderWidth: CGFloat = .zero {
    didSet { containerView.layer.borderWidth = borderWidth }
  }

  /// Border color applied to `containerView`.
  public var borderColor: UIColor = .clear {
    didSet { containerView.layer.borderColor = borderColor.cgColor }
  }

  /// Fill color applied to `containerView`.
  public var containerBackgroundColor: UIColor = .clear {
    didSet { containerView.backgroundColor = containerBackgroundColor }
  }

  /// Shadow color applied to cell layer.
  public var shadowColor: UIColor = .clear {
    didSet { layer.shadowColor = shadowColor.cgColor }
  }

  /// Shadow opacity applied to cell layer.
  public var shadowOpacity: Float = .zero {
    didSet { layer.shadowOpacity = shadowOpacity }
  }

  /// Shadow offset applied to cell layer.
  public var shadowOffset: CGSize = .zero {
    didSet { layer.shadowOffset = shadowOffset }
  }

  /// Shadow blur radius applied to cell layer.
  public var shadowRadius: CGFloat = .zero {
    didSet { layer.shadowRadius = shadowRadius }
  }

  /// Shadow path inset used to tune performance and appearance.
  public var shadowPathInset: CGFloat = .zero {
    didSet { setNeedsLayout() }
  }

  private var containerConstraints: [NSLayoutConstraint] = []
  private var hasPerformedInitialSetup = false

  public override init(frame: CGRect) {
    super.init(frame: frame)
    performInitialSetupIfNeeded()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    performInitialSetupIfNeeded()
  }

  open override func awakeFromNib() {
    super.awakeFromNib()
    performInitialSetupIfNeeded()
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    updateShadowPathIfNeeded()
  }

  /// Hook for subclass UI construction.
  ///
  /// Override this method to add and constrain subviews inside `containerView`.
  open func setupUI() {}

  /// Hook for subclass visual style configuration.
  open func setupStyle() {}

  /// Hook for subclass data binding.
  ///
  /// - Parameter model: Any model object used by subclass to update UI.
  open func bindData(_ model: Any) {}

  /// Applies surface style values in one call.
  public func configureSurface(
    cornerRadius: CGFloat,
    borderWidth: CGFloat = .zero,
    borderColor: UIColor = .clear,
    backgroundColor: UIColor = .clear
  ) {
    self.cornerRadius = cornerRadius
    self.borderWidth = borderWidth
    self.borderColor = borderColor
    self.containerBackgroundColor = backgroundColor
  }

  /// Applies shadow values in one call.
  public func configureShadow(
    color: UIColor,
    opacity: Float,
    offset: CGSize,
    radius: CGFloat,
    pathInset: CGFloat = .zero
  ) {
    shadowColor = color
    shadowOpacity = opacity
    shadowOffset = offset
    shadowRadius = radius
    shadowPathInset = pathInset
  }

  /// Registers this cell class to a collection view.
  ///
  /// This API is optional because `UICollectionView.fkDequeueCell(_:,for:)` performs lazy auto-registration.
  open class func register(to collectionView: UICollectionView) {
    collectionView.register(self, forCellWithReuseIdentifier: reuseIdentifier)
  }

  private func performInitialSetupIfNeeded() {
    guard !hasPerformedInitialSetup else { return }
    hasPerformedInitialSetup = true

    applyDefaultConfiguration()
    setupContainerView()
    setupUI()
    setupStyle()
  }

  private func applyDefaultConfiguration() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    clipsToBounds = false
    contentView.clipsToBounds = false
  }

  private func setupContainerView() {
    containerView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(containerView)
    updateContainerConstraints()
  }

  private func updateContainerConstraints() {
    NSLayoutConstraint.deactivate(containerConstraints)
    containerConstraints = [
      containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: containerInsets.top),
      containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: containerInsets.left),
      containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -containerInsets.right),
      containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -containerInsets.bottom),
    ]
    NSLayoutConstraint.activate(containerConstraints)
  }

  private func updateShadowPathIfNeeded() {
    guard shadowOpacity > .zero || shadowRadius > .zero else {
      layer.shadowPath = nil
      return
    }
    let pathRect = bounds.insetBy(dx: shadowPathInset, dy: shadowPathInset)
    layer.shadowPath = UIBezierPath(roundedRect: pathRect, cornerRadius: cornerRadius).cgPath
  }
}

public extension UICollectionView {
  /// Dequeues a reusable cell with lazy auto-registration.
  ///
  /// Registration is idempotent, so this method safely registers before dequeueing.
  func fkDequeueCell<T: FKBaseCollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
    register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    let cell = dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath)
    guard let typedCell = cell as? T else {
      fatalError("Failed to dequeue cell \(type.reuseIdentifier) as \(T.self).")
    }
    return typedCell
  }
}
