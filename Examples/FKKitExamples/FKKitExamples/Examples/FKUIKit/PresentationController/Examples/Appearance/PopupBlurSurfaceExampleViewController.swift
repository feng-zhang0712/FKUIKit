import UIKit
import FKUIKit

/// Demonstrates a blur material applied inside the popup surface itself (not the backdrop).
final class PopupBlurSurfaceExampleViewController: FKPresentationExamplePageViewController {
  private var styleIndex: Int = 0
  private var blurAlpha: Float = 1.0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Popup surface blur",
      subtitle: "Apply blur to the popup content surface, independent of backdrop style.",
      notes: "This demonstrates panel-level material styling. Backdrop remains a separate concern."
    )

    addView(
      FKExampleControls.segmented(
        title: "Material",
        items: ["systemMaterial", "systemThinMaterial", "systemThickMaterial"],
        selectedIndex: styleIndex
      ) { [weak self] idx in
        self?.styleIndex = idx
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Surface alpha",
        value: blurAlpha,
        range: 0.35...1.0,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] value in
        self?.blurAlpha = value
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let style: UIBlurEffect.Style = {
        switch self.styleIndex {
        case 1: return .systemThinMaterial
        case 2: return .systemThickMaterial
        default: return .systemMaterial
        }
      }()

      let content = PopupBlurSurfaceContentViewController(style: style, alpha: CGFloat(self.blurAlpha))
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .center(configuration.center)
      configuration.center.size = .fixed(CGSize(width: 360, height: 320))
      configuration.safeAreaPolicy = .containerRespectsSafeArea
      configuration.backdropStyle = .dim(alpha: 0.28)
      configuration.cornerRadius = 20
      configuration.shadow.opacity = 0.18
      configuration.shadow.radius = 22
      configuration.contentInsets = .zero

      FKPresentationController.present(
        contentController: content,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(),
        animated: true,
        completion: nil
      )
    }
  }
}

private final class PopupBlurSurfaceContentViewController: UIViewController {
  private let materialStyle: UIBlurEffect.Style
  private let materialAlpha: CGFloat

  init(style: UIBlurEffect.Style, alpha: CGFloat) {
    self.materialStyle = style
    self.materialAlpha = alpha
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: materialStyle))
    blurView.alpha = materialAlpha
    blurView.frame = view.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(blurView)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.textAlignment = .center
    titleLabel.text = "Blur Surface"

    let subtitleLabel = UILabel()
    subtitleLabel.font = .preferredFont(forTextStyle: .body)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = "The popup panel itself uses a blur material."

    [titleLabel, subtitleLabel].forEach { stack.addArrangedSubview($0) }
    blurView.contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -20),
      stack.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
    ])
  }
}
