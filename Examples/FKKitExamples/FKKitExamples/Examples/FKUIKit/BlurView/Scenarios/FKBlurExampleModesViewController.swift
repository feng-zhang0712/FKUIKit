import UIKit
import FKUIKit

// MARK: - Scenario: Static Blur

final class FKBlurStaticVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Static Blur"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // Static mode blurs once (on first need) and then reuses the result.
    blur.configuration = FKBlurConfiguration(
      mode: .static,
      backend: .custom(parameters: .init(blurRadius: 22, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)),
      downsampleFactor: 4
    )
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "mode: .static")

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "Static Blur",
      description: "Generates the blur result once.\nGreat for: posters, static backgrounds, fixed cards.",
      content: bg
    ))
  }
}

// MARK: - Scenario: Dynamic Blur (Scrolling Background)

final class FKBlurDynamicScrollVC: UIViewController {
  private let backgroundScroll = UIScrollView()
  private let content = UIStackView()
  private let blur = FKBlurView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic Blur (Scroll Refresh)"
    view.backgroundColor = .systemBackground

    // This demo refreshes the blurred content while the background scrolls.
    // - Point `blurSourceView` to the background content (exclude the blur view itself to avoid recursion).
    // - Use `mode = .dynamic` to refresh during scroll/animations.

    backgroundScroll.translatesAutoresizingMaskIntoConstraints = false
    backgroundScroll.alwaysBounceVertical = true
    view.addSubview(backgroundScroll)
    NSLayoutConstraint.activate([
      backgroundScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      backgroundScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      backgroundScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      backgroundScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    content.axis = .vertical
    content.spacing = 16
    content.translatesAutoresizingMaskIntoConstraints = false
    backgroundScroll.addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: backgroundScroll.topAnchor, constant: 16),
      content.leadingAnchor.constraint(equalTo: backgroundScroll.leadingAnchor, constant: 16),
      content.trailingAnchor.constraint(equalTo: backgroundScroll.trailingAnchor, constant: -16),
      content.bottomAnchor.constraint(equalTo: backgroundScroll.bottomAnchor, constant: -24),
      content.widthAnchor.constraint(equalTo: backgroundScroll.widthAnchor, constant: -32),
    ])

    (0..<20).forEach { i in
      let box = FKBlurExampleUI.makeColorfulBackgroundView(height: 140)
      let label = UILabel()
      label.text = "Scrolling background #\(i)"
      label.textColor = .white
      label.font = .preferredFont(forTextStyle: .headline)
      label.translatesAutoresizingMaskIntoConstraints = false
      box.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
        label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -14),
      ])
      content.addArrangedSubview(box)
    }

    blur.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(blur)
    NSLayoutConstraint.activate([
      blur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      blur.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      blur.widthAnchor.constraint(equalToConstant: 260),
      blur.heightAnchor.constraint(equalToConstant: 96),
    ])

    blur.blurSourceView = backgroundScroll // Snapshot source for the custom backend
    blur.configuration = FKBlurConfiguration(
      mode: .dynamic,
      backend: .custom(parameters: .init(blurRadius: 18, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)),
      opacity: 1.0,
      downsampleFactor: 4,
      preferredFramesPerSecond: 60
    )
    blur.maskedCornerRadius = 16
    FKBlurExampleUI.addOverlayText(to: blur, text: "Live refresh while scrolling")
  }
}
