import UIKit
import FKUIKit

/// Single anchor popup example.
///
/// This page intentionally keeps only one anchor bar at the top.
/// Tapping the bar toggles an embedded popup below it.
final class AnchorTopSingleExampleViewController: UIViewController {
  private let anchorBar = UIButton(type: .system)
  private var activePresentation: FKPresentationController?

  private var maskAlpha: Float = 0.25
  private var cornerRadius: Float = 12
  private var contentHeight: Float = 260
  private var showsShadow: Bool = true
  private var animated: Bool = true

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = "Anchor"

    configureAnchorBar()
    let controls = makeControls()

    view.addSubview(anchorBar)
    view.addSubview(controls)
    NSLayoutConstraint.activate([
      anchorBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      anchorBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      anchorBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      anchorBar.heightAnchor.constraint(equalToConstant: 52),

      controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      controls.topAnchor.constraint(equalTo: anchorBar.bottomAnchor, constant: 16),
    ])
  }

  private func configureAnchorBar() {
    anchorBar.translatesAutoresizingMaskIntoConstraints = false
    anchorBar.configuration = .filled()
    anchorBar.configuration?.title = "Tap top anchor to present"
    anchorBar.configuration?.baseBackgroundColor = .white
    anchorBar.configuration?.baseForegroundColor = .label
    anchorBar.configuration?.cornerStyle = .fixed
    anchorBar.configuration?.background.cornerRadius = 0
    anchorBar.contentHorizontalAlignment = .leading
    anchorBar.addAction(UIAction { [weak self] _ in
      self?.togglePopup()
    }, for: .touchUpInside)
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

  @MainActor
  private func togglePopup() {
    if let activePresentation {
      activePresentation.dismiss(animated: animated) { [weak self] in
        self?.activePresentation = nil
      }
      return
    }
    presentPopup()
  }

  @MainActor
  private func presentPopup() {
    let anchor = FKAnchor(
      sourceView: anchorBar,
      edge: .bottom,
      direction: .down,
      alignment: .fill,
      widthPolicy: .matchContainer,
      offset: 0
    )
    let embedded = FKEmbeddedAnchorConfiguration(
      anchor: anchor,
      hostStrategy: .inSameSuperviewBelowAnchor,
      zOrderPolicy: .keepAnchorAbovePresentation,
      maskCoveragePolicy: .belowAnchorOnly,
      dismissBehavior: .init(allowsTapToDismiss: true, allowsSwipeToDismiss: true)
    )

    var configuration = FKPresentationConfiguration()
    configuration.mode = .anchorEmbedded(embedded)
    configuration.backdrop.style = .dim(color: .black, alpha: CGFloat(maskAlpha))
    configuration.cornerRadius = CGFloat(cornerRadius)
    if !showsShadow {
      configuration.shadow.opacity = 0
      configuration.shadow.radius = 0
      configuration.shadow.offset = .zero
    }

    let content = FKExampleLabelContentViewController(text: "Anchor popup content")
    content.preferredContentSize = .init(width: 0, height: CGFloat(contentHeight))

    activePresentation = FKPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      delegate: nil,
      callbacks: .init(didDismiss: { [weak self] in
        self?.activePresentation = nil
      }),
      animated: animated,
      completion: nil
    )
  }
}

