import UIKit

/// A single swipe action button model used by `FKSwipeAction`.
///
/// Use this type to describe **one** action shown when a list cell is swiped.
/// Each button can be customized independently (title, icon, layout, background, width, corner radius),
/// and provides a tap callback.
///
/// ## Example
/// ```swift
/// let delete = FKSwipeActionButton(
///   id: "delete",
///   title: "Delete",
///   icon: UIImage(systemName: "trash.fill"),
///   background: .color(.systemRed),
///   layout: .iconTop,
///   width: 86,
///   cornerRadius: 14
/// ) {
///   // handle delete
/// }
/// ```
public struct FKSwipeActionButton: Sendable {
  /// Visual layout for the button content (title/icon arrangement).
  public enum ContentLayout: Sendable {
    /// Title only.
    case title
    /// Icon only.
    case icon
    /// Icon above title (vertical stack).
    case iconTop
    /// Icon leading title (horizontal stack).
    case iconLeading
  }

  /// Background rendering style for the button.
  public enum Background: Sendable {
    /// Solid color background.
    case color(UIColor)
    /// Vertical gradient background (top → bottom).
    case verticalGradient(top: UIColor, bottom: UIColor)
    /// Horizontal gradient background (leading → trailing).
    case horizontalGradient(leading: UIColor, trailing: UIColor)
  }

  /// Stable identity for event reporting and business routing.
  ///
  /// This value is reported by `FKSwipeActionConfiguration.Event.didTapAction`.
  public let id: String
  /// Optional title text displayed on the button.
  public var title: String?
  /// Optional icon image displayed on the button.
  public var icon: UIImage?
  /// Background style.
  public var background: Background
  /// Title font used for `title`.
  public var font: UIFont
  /// Title color used for `title`.
  public var titleColor: UIColor
  /// Content layout.
  public var layout: ContentLayout
  /// Button width in points.
  ///
  /// Multiple buttons will be laid out horizontally; the total reveal width equals the sum of widths.
  public var width: CGFloat
  /// Corner radius applied to the button container.
  public var cornerRadius: CGFloat
  /// Tap handler called when this action is triggered.
  ///
  /// - Important: The handler is executed on the main thread (UI-safe).
  public var handler: (@Sendable () -> Void)?

  /// Creates an action button.
  ///
  /// - Parameters:
  ///   - id: Stable identifier for the action.
  ///   - title: Optional title text.
  ///   - icon: Optional icon image.
  ///   - background: Background style (solid or gradient).
  ///   - font: Title font.
  ///   - titleColor: Title (and icon tint) color.
  ///   - layout: Content layout style.
  ///   - width: Button width in points.
  ///   - cornerRadius: Corner radius.
  ///   - handler: Tap callback.
  public init(
    id: String,
    title: String? = nil,
    icon: UIImage? = nil,
    background: Background,
    font: UIFont = .systemFont(ofSize: 15, weight: .regular),
    titleColor: UIColor = .white,
    layout: ContentLayout = .title,
    width: CGFloat = 72,
    cornerRadius: CGFloat = 0,
    handler: (@Sendable () -> Void)? = nil
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.background = background
    self.font = font
    self.titleColor = titleColor
    self.layout = layout
    self.width = width
    self.cornerRadius = cornerRadius
    self.handler = handler
  }
}

// MARK: - Internal UIKit rendering

final class FKSwipeActionButtonView: UIControl {
  // The immutable model used for view construction.
  private let model: FKSwipeActionButton
  // Icon view (tinted with `titleColor`).
  private let imageView = UIImageView()
  // Title label (centered, multi-line).
  private let titleLabel = UILabel()
  // Container stack to support multiple content layouts.
  private let stack = UIStackView()
  // Background gradient layer (inserted only for gradient backgrounds).
  private let gradientLayer = CAGradientLayer()

  // Internal tap callback bridged to manager.
  var onTap: (() -> Void)?

  init(model: FKSwipeActionButton) {
    self.model = model
    super.init(frame: .zero)
    isExclusiveTouch = true
    clipsToBounds = true
    layer.cornerRadius = model.cornerRadius

    setupBackground()
    setupContent()

    addTarget(self, action: #selector(tapped), for: .touchUpInside)
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Keep gradient aligned with view bounds.
    gradientLayer.frame = bounds
  }

  private func setupBackground() {
    switch model.background {
    case .color(let color):
      backgroundColor = color
    case .verticalGradient(let top, let bottom):
      backgroundColor = .clear
      // Use CAGradientLayer for high-performance gradient rendering.
      gradientLayer.colors = [top.cgColor, bottom.cgColor]
      gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
      gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
      layer.insertSublayer(gradientLayer, at: 0)
    case .horizontalGradient(let leading, let trailing):
      backgroundColor = .clear
      // Use CAGradientLayer for high-performance gradient rendering.
      gradientLayer.colors = [leading.cgColor, trailing.cgColor]
      gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
      gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
      layer.insertSublayer(gradientLayer, at: 0)
    }
  }

  private func setupContent() {
    // Frame/layout updates are managed by the holder for smooth 60fps swiping.
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.alignment = .center
    stack.distribution = .equalCentering
    stack.spacing = 4
    addSubview(stack)

    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = model.titleColor
    imageView.image = model.icon

    titleLabel.font = model.font
    titleLabel.textColor = model.titleColor
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 2
    titleLabel.text = model.title

    switch model.layout {
    case .title:
      stack.axis = .vertical
      stack.addArrangedSubview(titleLabel)
    case .icon:
      stack.axis = .vertical
      stack.addArrangedSubview(imageView)
    case .iconTop:
      stack.axis = .vertical
      stack.addArrangedSubview(imageView)
      stack.addArrangedSubview(titleLabel)
    case .iconLeading:
      stack.axis = .horizontal
      stack.addArrangedSubview(imageView)
      stack.addArrangedSubview(titleLabel)
    }

    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
      stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
    ])
  }

  @objc private func tapped() {
    // Forward to holder/manager.
    onTap?()
  }
}

