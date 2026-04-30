import UIKit
import FKUIKit

/// Shared base page for single-anchor popup demos.
///
/// Subclasses provide anchor placement and anchor geometry, while this base handles:
/// - shared controls
/// - anchor tap gesture
/// - popup present/dismiss lifecycle
/// - shadow/corner/mask tuning
@MainActor
class AnchorSingleExampleBaseViewController: UIViewController {
  enum AnchorPlacement {
    case top
    case bottom
  }

  struct AnchorDemoSpec {
    let pageTitle: String
    let anchorTitle: String
    let popupContentText: String
    let placement: AnchorPlacement
    let edge: FKAnchor.Edge
    let direction: FKAnchor.Direction
    let helperText: String?
  }

  private(set) lazy var anchorView: UIView = makeAnchorView()
  private let anchorTitleLabel = UILabel()
  private var anchorHeightConstraint: NSLayoutConstraint?
  private var activePresentation: FKPresentationController?

  private var maskAlpha: Float = 0.25
  private var cornerRadius: Float = 12
  private var contentHeight: Float = 260
  private var showsShadow: Bool = true
  private var animated: Bool = true

  var spec: AnchorDemoSpec {
    fatalError("Subclasses must override `spec`.")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = spec.pageTitle

    let controls = makeControls()
    view.addSubview(controls)
    view.addSubview(anchorView)

    switch spec.placement {
    case .top:
      anchorHeightConstraint = anchorView.heightAnchor.constraint(equalToConstant: 52)
      NSLayoutConstraint.activate([
        anchorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        anchorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        anchorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        anchorHeightConstraint!,

        controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
        controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        controls.topAnchor.constraint(equalTo: anchorView.bottomAnchor, constant: 16),
      ])
    case .bottom:
      anchorHeightConstraint = anchorView.heightAnchor.constraint(equalToConstant: 52)
      NSLayoutConstraint.activate([
        controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
        controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        controls.bottomAnchor.constraint(lessThanOrEqualTo: anchorView.topAnchor, constant: -16),

        anchorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        anchorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        anchorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        anchorHeightConstraint!,
      ])
    }
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    guard spec.placement == .bottom else { return }
    // Keep the anchor visually attached to the physical screen bottom while reserving safe-area space.
    anchorHeightConstraint?.constant = 52 + view.safeAreaInsets.bottom
  }

  private func makeAnchorView() -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .white

    anchorTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    anchorTitleLabel.text = spec.anchorTitle
    anchorTitleLabel.font = .preferredFont(forTextStyle: .body)
    anchorTitleLabel.textColor = .label
    container.addSubview(anchorTitleLabel)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleAnchorTap))
    container.addGestureRecognizer(tap)
    container.isUserInteractionEnabled = true

    NSLayoutConstraint.activate([
      anchorTitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      anchorTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
      anchorTitleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
      anchorTitleLabel.heightAnchor.constraint(equalToConstant: 24),
    ])
    return container
  }

  private func makeControls() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    let subtitle = UILabel()
    subtitle.text = "Controls (live configuration)"
    subtitle.font = .preferredFont(forTextStyle: .headline)
    stack.addArrangedSubview(subtitle)

    if let helperText = spec.helperText {
      let helper = UILabel()
      helper.text = helperText
      helper.numberOfLines = 0
      helper.font = .preferredFont(forTextStyle: .footnote)
      helper.textColor = .secondaryLabel
      stack.addArrangedSubview(helper)
    }

    let shadow = FKExampleControls.toggle(title: "Show shadow", isOn: showsShadow) { [weak self] isOn in
      self?.showsShadow = isOn
    }
    stack.addArrangedSubview(shadow)

    let animation = FKExampleControls.segmented(
      title: "Animation",
      items: ["Animated", "No animation"],
      selectedIndex: animated ? 0 : 1
    ) { [weak self] index in
      self?.animated = (index == 0)
    }
    stack.addArrangedSubview(animation)

    let mask = FKExampleControls.slider(title: "Mask alpha", value: maskAlpha, range: 0...0.6) { [weak self] v in
      self?.maskAlpha = v
    }
    stack.addArrangedSubview(mask)

    let radius = FKExampleControls.slider(title: "Corner radius", value: cornerRadius, range: 0...24) { [weak self] v in
      self?.cornerRadius = v
    }
    stack.addArrangedSubview(radius)

    let height = FKExampleControls.slider(
      title: "Content height",
      value: contentHeight,
      range: 160...520,
      valueText: { "\(Int($0))pt" }
    ) { [weak self] v in
      self?.contentHeight = v
    }
    stack.addArrangedSubview(height)

    return stack
  }

  @objc
  private func handleAnchorTap() {
    if let activePresentation {
      activePresentation.dismiss(animated: animated) { [weak self] in
        self?.activePresentation = nil
      }
      return
    }
    presentPopup()
  }

  private func presentPopup() {
    let anchor = FKAnchor(
      sourceView: anchorView,
      edge: spec.edge,
      direction: spec.direction,
      alignment: .fill,
      widthPolicy: .matchContainer,
      offset: 0
    )
    let anchorConfig = FKAnchorConfiguration(
      anchor: anchor,
      hostStrategy: .inSameSuperviewBelowAnchor,
      zOrderPolicy: .keepAnchorAbovePresentation,
      maskCoveragePolicy: .fullScreen
    )

    var configuration = FKPresentationConfiguration()
    configuration.layout = .anchor(anchorConfig)
    configuration.dismissBehavior = .init(allowsTapOutside: true, allowsSwipe: true, allowsBackdropTap: true)
    configuration.backdropStyle = .dim(color: .black, alpha: CGFloat(maskAlpha))
    configuration.cornerRadius = CGFloat(cornerRadius)
    if showsShadow {
      configuration.shadow.opacity = 0.18
      configuration.shadow.radius = 16
      configuration.shadow.offset = .init(width: 0, height: 8)
    } else {
      configuration.shadow.opacity = 0
      configuration.shadow.radius = 0
      configuration.shadow.offset = .zero
    }

    let content = FKExampleLabelContentViewController(text: spec.popupContentText)
    content.preferredContentSize = .init(width: 0, height: CGFloat(contentHeight))

    activePresentation = FKPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      delegate: nil,
      handlers: .init(didDismiss: { [weak self] in
        self?.activePresentation = nil
      }),
      animated: animated,
      completion: nil
    )
  }
}
