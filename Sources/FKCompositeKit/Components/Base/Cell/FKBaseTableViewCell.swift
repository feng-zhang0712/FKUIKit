//
// FKBaseTableViewCell.swift
// FKCompositeKit
//

import UIKit

/// A reusable, extensible base class for `UITableViewCell`.
///
/// This class standardizes initialization flow, style setup, layout entry points, and data binding.
/// Subclasses only need to override `setupUI()`, `setupStyle()`, and `bindData(_:)`.
open class FKBaseTableViewCell: UITableViewCell {

  /// Default reusable identifier derived from class name.
  open class var reuseIdentifier: String {
    String(describing: self)
  }

  /// Main container view used by subclasses to build UI content.
  ///
  /// Build all custom subviews inside this container instead of attaching directly to `contentView`.
  /// This keeps style and layout behavior consistent across large projects.
  public let containerView = UIView()

  /// Content insets applied to `containerView` inside `contentView`.
  ///
  /// Update this value before layout to support design-system spacing.
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
  ///
  /// Negative values expand the path; positive values shrink it.
  public var shadowPathInset: CGFloat = .zero {
    didSet { setNeedsLayout() }
  }

  private var containerConstraints: [NSLayoutConstraint] = []
  private var hasPerformedInitialSetup = false

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
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
  ///
  /// Override this method to configure fonts, colors, spacing, and other appearance behavior.
  open func setupStyle() {}

  /// Hook for subclass data binding.
  ///
  /// - Parameter model: Any model object used by subclass to update UI.
  open func bindData(_ model: Any) {}

  /// Applies surface style values in one call.
  ///
  /// - Parameters:
  ///   - cornerRadius: Corner radius on `containerView`.
  ///   - borderWidth: Border width on `containerView`.
  ///   - borderColor: Border color on `containerView`.
  ///   - backgroundColor: Fill color on `containerView`.
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
  ///
  /// - Parameters:
  ///   - color: Shadow color.
  ///   - opacity: Shadow opacity.
  ///   - offset: Shadow offset.
  ///   - radius: Shadow blur radius.
  ///   - pathInset: Optional path inset used to tune shadow bounds.
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

  /// Registers this cell class to a table view.
  ///
  /// This API is optional because `UITableView.fkDequeueCell(_:,for:)` performs lazy auto-registration.
  open class func register(to tableView: UITableView) {
    tableView.register(self, forCellReuseIdentifier: reuseIdentifier)
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
    selectionStyle = .none
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

public extension UITableView {
  /// Dequeues a reusable cell with lazy auto-registration.
  ///
  /// Registration is idempotent, so this method safely registers before dequeueing.
  func fkDequeueCell<T: FKBaseTableViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
    register(type, forCellReuseIdentifier: type.reuseIdentifier)
    let cell = dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath)
    guard let typedCell = cell as? T else {
      fatalError("Failed to dequeue cell \(type.reuseIdentifier) as \(T.self).")
    }
    return typedCell
  }
}
