import UIKit
import FKUIKit

/// Demonstrates blur material applied to a top-anchor popup container (same geometry as `Top Anchor`).
final class AnchorBlurExampleViewController: FKPresentationBlurExampleBaseViewController {
  private let anchorBar = UIView()
  private let anchorTitleLabel = UILabel()
  private var activePresentation: FKPresentationController?

  private var showsShadow: Bool = true
  private var cornerRadius: Float = 12
  private var contentHeight: Float = 260

  override var pinnedTopView: UIView? { anchorBar }

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Anchor popup blur",
      subtitle: "Top anchor popup with container blur (matches Top Anchor geometry).",
      notes: "Tap the top anchor bar to present/dismiss."
    )

    applyPreset(.systemSheetLike)
    dimAlpha = 0.25
    tintColor = .systemTeal

    configureAnchorBar()
    addAnchorSpecificControls()
    addSharedBlurControls()

    // Make it obvious how to trigger it.
    addView(FKExampleControls.infoLabel(text: "Tap the top white anchor bar to present/dismiss."))
  }

  private func configureAnchorBar() {
    anchorBar.backgroundColor = .white
    anchorBar.heightAnchor.constraint(equalToConstant: 52).isActive = true

    anchorTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    anchorTitleLabel.text = "Tap top anchor to present"
    anchorTitleLabel.font = .preferredFont(forTextStyle: .body)
    anchorTitleLabel.textColor = .label
    anchorBar.addSubview(anchorTitleLabel)

    NSLayoutConstraint.activate([
      anchorTitleLabel.leadingAnchor.constraint(equalTo: anchorBar.leadingAnchor, constant: 16),
      anchorTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: anchorBar.trailingAnchor, constant: -16),
      anchorTitleLabel.topAnchor.constraint(equalTo: anchorBar.topAnchor, constant: 14),
      anchorTitleLabel.heightAnchor.constraint(equalToConstant: 24),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleAnchorTap))
    anchorBar.addGestureRecognizer(tap)
    anchorBar.isUserInteractionEnabled = true
  }

  private func addAnchorSpecificControls() {
    addSectionTitle("Anchor popup appearance")
    addView(FKExampleControls.toggle(title: "Show shadow", isOn: showsShadow) { [weak self] isOn in
      self?.showsShadow = isOn
    })
    addView(FKExampleControls.slider(
      title: "Corner radius",
      value: cornerRadius,
      range: 0...24,
      valueText: { String(format: "%.0f", $0) }
    ) { [weak self] value in
      self?.cornerRadius = value
    })
    addView(FKExampleControls.slider(
      title: "Content height",
      value: contentHeight,
      range: 160...520,
      valueText: { "\(Int($0))pt" }
    ) { [weak self] value in
      self?.contentHeight = value
    })
  }

  @objc
  private func handleAnchorTap() {
    if let activePresentation {
      activePresentation.dismiss(animated: true) { [weak self] in
        self?.activePresentation = nil
      }
      return
    }
    presentPopup()
  }

  private func presentPopup() {
    let anchor = FKAnchor(
      sourceView: anchorBar,
      edge: .bottom,
      direction: .down,
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
    configuration.cornerRadius = CGFloat(cornerRadius)
    configuration.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
    if showsShadow {
      configuration.shadow.opacity = 0.18
      configuration.shadow.radius = 16
      configuration.shadow.offset = .init(width: 0, height: 8)
    } else {
      configuration.shadow.opacity = 0
      configuration.shadow.radius = 0
      configuration.shadow.offset = .zero
    }
    applyCommonBlurConfiguration(to: &configuration)

    let content = FKExampleLabelContentViewController(text: "Top anchor popup blur", usesTransparentBackground: true)
    content.preferredContentSize = .init(width: 0, height: CGFloat(contentHeight))

    activePresentation = FKPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      delegate: nil,
      handlers: .init(didDismiss: { [weak self] in
        self?.activePresentation = nil
      }),
      animated: true,
      completion: nil
    )
  }
}

