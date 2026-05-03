import UIKit
import FKUIKit

// MARK: - Scenario: XIB / Storyboard

final class FKBlurXIBDemoVC: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "XIB / Storyboard"
    view.backgroundColor = .systemGroupedBackground

    // Notes:
    // - This demo loads a preconfigured FKBlurView from a XIB.
    // - In Interface Builder you can drop a UIView, set its class to FKBlurView,
    //   then tune the IBInspectable properties (ibBackend / ibMode / ibBlurRadius …).

    let host = UIView()
    host.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host)
    NSLayoutConstraint.activate([
      host.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      host.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      host.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      host.heightAnchor.constraint(equalToConstant: 220),
    ])

    let bg = FKBlurExampleUI.makeColorfulBackgroundView(height: 220)
    host.addSubview(bg)
    bg.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bg.topAnchor.constraint(equalTo: host.topAnchor),
      bg.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      bg.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      bg.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])

    // Load a preconfigured FKBlurView from XIB.
    let nibBlur = loadNibBlurView()
    nibBlur.maskedCornerRadius = 16
    nibBlur.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(nibBlur)
    NSLayoutConstraint.activate([
      nibBlur.centerXAnchor.constraint(equalTo: host.centerXAnchor),
      nibBlur.centerYAnchor.constraint(equalTo: host.centerYAnchor),
      nibBlur.widthAnchor.constraint(equalToConstant: 260),
      nibBlur.heightAnchor.constraint(equalToConstant: 96),
    ])
    FKBlurExampleUI.addOverlayText(to: nibBlur, text: "Loaded from XIB")

    let label = UILabel()
    label.text = "Note: FKBlurViewXIBDemoView.xib is configured with ibBackend/ibMode/ibBlurRadius, etc."
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: host.bottomAnchor, constant: 12),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  private func loadNibBlurView() -> FKBlurView {
    let name = "FKBlurViewXIBDemoView"
    let bundle = Bundle.main

    // `loadNibNamed` can raise an Objective-C exception if the nib is missing.
    // Guard file existence first to keep this demo always runnable.
    guard bundle.path(forResource: name, ofType: "nib") != nil else {
      return makeFallbackBlurView()
    }

    let objs = bundle.loadNibNamed(name, owner: nil, options: nil) ?? []
    if let v = objs.first(where: { $0 is FKBlurView }) as? FKBlurView { return v }
    return makeFallbackBlurView()
  }

  private func makeFallbackBlurView() -> FKBlurView {
    let fallback = FKBlurView()
    fallback.configuration = FKBlurConfiguration(
      mode: .dynamic,
      backend: .custom(parameters: .init(blurRadius: 18, saturation: 1.0, brightness: 0.0, tintColor: .systemBlue, tintOpacity: 0.12)),
      downsampleFactor: 4
    )
    return fallback
  }
}
