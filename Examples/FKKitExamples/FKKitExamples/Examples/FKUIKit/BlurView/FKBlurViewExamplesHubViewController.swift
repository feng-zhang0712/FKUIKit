import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

// Notes:
// - This file contains FKBlurView’s hub list and scenario pages.
// - Demos are intentionally minimal: only the essential integration code you can copy into your app.
// - iOS 13+ compatible, Auto Layout everywhere, supports rotation.

// MARK: - Shared Demo UI Helpers

private enum FKBlurDemoUI {
  /// Shared scroll container so all demos stay accessible (rotation / small screens / large text).
  static func makeScrollStack(in viewController: UIViewController) -> UIStackView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)

    viewController.view.addSubview(scroll)
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),

      stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32),
    ])

    return stack
  }

  /// A simple demo card: title + description + live preview.
  static func card(title: String, description: String, content: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 10
    wrap.backgroundColor = .secondarySystemGroupedBackground
    wrap.layer.cornerRadius = 12
    wrap.isLayoutMarginsRelativeArrangement = true
    wrap.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

    let t = UILabel()
    t.text = title
    t.font = .preferredFont(forTextStyle: .headline)

    let d = UILabel()
    d.text = description
    d.textColor = .secondaryLabel
    d.numberOfLines = 0
    d.font = .preferredFont(forTextStyle: .footnote)

    wrap.addArrangedSubview(t)
    wrap.addArrangedSubview(d)
    wrap.addArrangedSubview(content)
    return wrap
  }

  /// A vivid background to make blur effects obvious.
  static func makeColorfulBackgroundView(height: CGFloat = 160) -> UIView {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    v.layer.cornerRadius = 14
    v.clipsToBounds = true

    // Gradient background (no third-party dependencies).
    let gradient = CAGradientLayer()
    gradient.colors = [
      UIColor.systemPink.cgColor,
      UIColor.systemPurple.cgColor,
      UIColor.systemBlue.cgColor,
      UIColor.systemTeal.cgColor,
    ]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    gradient.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    v.layer.insertSublayer(gradient, at: 0)

    // A label that makes it clear what content is being blurred.
    let label = UILabel()
    label.text = "Background content (to be blurred)"
    label.textColor = .white
    label.font = .preferredFont(forTextStyle: .headline)
    label.translatesAutoresizingMaskIntoConstraints = false
    v.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
      label.topAnchor.constraint(equalTo: v.topAnchor, constant: 14),
    ])

    // Keep gradient in sync with bounds after rotation/layout.
    v.fk_onLayout { [weak v] in
      guard let v else { return }
      (v.layer.sublayers?.first { $0 is CAGradientLayer } as? CAGradientLayer)?.frame = v.bounds
    }
    return v
  }

  /// Embed a centered blur view (reused across demos).
  static func embedCenteredBlurView(
    _ blurView: FKBlurView,
    on background: UIView,
    size: CGSize = .init(width: 220, height: 90)
  ) {
    blurView.translatesAutoresizingMaskIntoConstraints = false
    background.addSubview(blurView)
    NSLayoutConstraint.activate([
      blurView.centerXAnchor.constraint(equalTo: background.centerXAnchor),
      blurView.centerYAnchor.constraint(equalTo: background.centerYAnchor),
      blurView.widthAnchor.constraint(equalToConstant: size.width),
      blurView.heightAnchor.constraint(equalToConstant: size.height),
    ])
  }

  /// Overlay label placed inside the blur region for easy comparison.
  static func addOverlayText(to blurView: UIView, text: String = "Blur Area") {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false
    blurView.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
    ])
  }
}

// MARK: - Base

private class FKBlurDemoBaseViewController: UIViewController {
  var stack: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    stack = FKBlurDemoUI.makeScrollStack(in: self)
  }
}

// MARK: - Hub

final class FKBlurViewExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: "Basic Blur View", subtitle: "The simplest FKBlurView (system material)", make: { FKBlurBasicVC() }),
    Row(title: "All System Styles", subtitle: "Preview light/dark/extraLight/systemMaterial…", make: { FKBlurAllSystemStylesVC() }),
    Row(title: "Custom Blur Radius", subtitle: "Custom blurRadius demo", make: { FKBlurCustomRadiusVC() }),
    Row(title: "Custom Saturation", subtitle: "Custom saturation demo", make: { FKBlurCustomSaturationVC() }),
    Row(title: "Custom Brightness", subtitle: "Custom brightness demo", make: { FKBlurCustomBrightnessVC() }),
    Row(title: "Custom Tint Overlay", subtitle: "Custom tintColor + tintOpacity demo", make: { FKBlurCustomTintVC() }),
    Row(title: "Static Blur", subtitle: "mode = .static (blur once, maximum performance)", make: { FKBlurStaticVC() }),
    Row(title: "Dynamic Blur (Scroll)", subtitle: "mode = .dynamic (refresh while scrolling)", make: { FKBlurDynamicScrollVC() }),
    Row(title: "Image Blur", subtitle: "UIImage.fk_blurred(...) demo", make: { FKBlurImageBlurVC() }),
    Row(title: "UIView Snapshot Blur", subtitle: "UIView.fk_blurredSnapshot sync/async demo", make: { FKBlurUIViewSnapshotVC() }),
    Row(title: "Rounded Rect Blur", subtitle: "maskedCornerRadius demo", make: { FKBlurRoundedRectVC() }),
    Row(title: "Circular Blur", subtitle: "maskPath = ovalInRect demo", make: { FKBlurCircleVC() }),
    Row(title: "Custom Mask", subtitle: "Arbitrary maskPath demo", make: { FKBlurCustomMaskVC() }),
    Row(title: "Semi-Transparent Blur", subtitle: "opacity demo", make: { FKBlurOpacityVC() }),
    Row(title: "Global Defaults", subtitle: "FKBlurGlobalDefaults.configuration demo", make: { FKBlurGlobalConfigVC() }),
    Row(title: "XIB / Storyboard", subtitle: "Load a FKBlurView from a XIB", make: { FKBlurXIBDemoVC() }),
    Row(title: "SwiftUI Demo", subtitle: "FKSwiftUIBlurView demo", make: { FKBlurSwiftUIHostVC() }),
    Row(title: "Dark Mode", subtitle: "Switch Light/Dark and inspect materials", make: { FKBlurDarkModeVC() }),
    Row(title: "Rotation", subtitle: "Auto Layout + refresh after rotation", make: { FKBlurRotationVC() }),
    Row(title: "Scroll Performance", subtitle: "Validate smooth 60fps scrolling", make: { FKBlurPerformanceTestVC() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBlurView"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var cfg = cell.defaultContentConfiguration()
    cfg.text = row.title
    cfg.secondaryText = row.subtitle
    cfg.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = cfg
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}

// MARK: - Scenario: Basic Blur

fileprivate final class FKBlurBasicVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic Blur View"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // Minimal usage: initialize and add to view hierarchy.
    // It uses `FKBlurGlobalDefaults.configuration` as the baseline (systemMaterial by default).
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur)

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "One-line setup",
      description: "let blur = FKBlurView() // default systemMaterial\nGreat for: cards, headers, overlays.",
      content: bg
    ))
  }
}

// MARK: - Scenario: All System Styles

fileprivate final class FKBlurAllSystemStylesVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "All System Styles"

    // System materials are hardware accelerated and the recommended choice for dynamic content.
    FKBlurConfiguration.SystemStyle.allCases.forEach { style in
      let bg = FKBlurDemoUI.makeColorfulBackgroundView(height: 130)
      let blur = FKBlurView()
      blur.configuration = FKBlurConfiguration(backend: .system(style: style))
      FKBlurDemoUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 240, height: 74))
      FKBlurDemoUI.addOverlayText(to: blur, text: "style: \(style)")
      stack.addArrangedSubview(FKBlurDemoUI.card(
        title: "\(style)",
        description: "Built-in system material (`UIBlurEffect.Style`). Best for dynamic scenarios.",
        content: bg
      ))
    }
  }
}

// MARK: - Scenario: Custom Parameters (Radius / Saturation / Brightness / Tint)

fileprivate final class FKBlurCustomRadiusVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Blur Radius"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // The custom backend provides full control via Core Image (Metal accelerated when available).
    let params = FKBlurConfiguration.CustomParameters(blurRadius: 10, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "blurRadius: 10")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "blurRadius = 10",
      description: "Example value. Adjust blurRadius as needed.",
      content: bg
    ))

    let bg2 = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur2 = FKBlurView()
    let params2 = FKBlurConfiguration.CustomParameters(blurRadius: 28, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur2.configuration = FKBlurConfiguration(backend: .custom(parameters: params2), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur2, on: bg2)
    FKBlurDemoUI.addOverlayText(to: blur2, text: "blurRadius: 28")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "blurRadius = 28",
      description: "Larger radius produces fewer background details.",
      content: bg2
    ))
  }
}

fileprivate final class FKBlurCustomSaturationVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Saturation"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    let params = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 0.6, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "saturation: 0.6")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "saturation = 0.6 (desaturated)",
      description: "Often used for a softer, calmer background material.",
      content: bg
    ))

    let bg2 = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur2 = FKBlurView()
    let params2 = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.4, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur2.configuration = FKBlurConfiguration(backend: .custom(parameters: params2), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur2, on: bg2)
    FKBlurDemoUI.addOverlayText(to: blur2, text: "saturation: 1.4")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "saturation = 1.4 (more vivid)",
      description: "Often used for a more vibrant material look.",
      content: bg2
    ))
  }
}

fileprivate final class FKBlurCustomBrightnessVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Brightness"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    let params = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.0, brightness: -0.10, tintColor: nil, tintOpacity: 0)
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "brightness: -0.10")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "brightness = -0.10 (darker)",
      description: "Use brightness to tune the overall mood.",
      content: bg
    ))

    let bg2 = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur2 = FKBlurView()
    let params2 = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.0, brightness: 0.12, tintColor: nil, tintOpacity: 0)
    blur2.configuration = FKBlurConfiguration(backend: .custom(parameters: params2), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur2, on: bg2)
    FKBlurDemoUI.addOverlayText(to: blur2, text: "brightness: 0.12")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "brightness = 0.12 (brighter)",
      description: "A brighter, hazier look for light backgrounds.",
      content: bg2
    ))
  }
}

fileprivate final class FKBlurCustomTintVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Tint Overlay"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // tintColor + tintOpacity adds a simple overlay, useful for brand/theme-tinted materials.
    let params = FKBlurConfiguration.CustomParameters(
      blurRadius: 18,
      saturation: 1.0,
      brightness: 0.0,
      tintColor: .systemIndigo,
      tintOpacity: 0.18
    )
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "tint: indigo (0.18)")
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "tintColor + tintOpacity",
      description: "Apply a tint overlay to quickly get a brand/theme feel.",
      content: bg
    ))
  }
}

// MARK: - Scenario: Static Blur

fileprivate final class FKBlurStaticVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Static Blur"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // Static mode blurs once (on first need) and then reuses the result.
    blur.configuration = FKBlurConfiguration(
      mode: .static,
      backend: .custom(parameters: .init(blurRadius: 22, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)),
      downsampleFactor: 4
    )
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "mode: .static")

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "Static Blur",
      description: "Generates the blur result once.\nGreat for: posters, static backgrounds, fixed cards.",
      content: bg
    ))
  }
}

// MARK: - Scenario: Dynamic Blur (Scrolling Background)

fileprivate final class FKBlurDynamicScrollVC: UIViewController {
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
      let box = FKBlurDemoUI.makeColorfulBackgroundView(height: 140)
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
    FKBlurDemoUI.addOverlayText(to: blur, text: "Live refresh while scrolling")
  }
}

// MARK: - Scenario: Image Blur

fileprivate final class FKBlurImageBlurVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Image Blur (UIImage)"

    // No view required: blur a UIImage directly (thumbnails, background images, etc.).
    let image = makeDemoImage()
    let params = FKBlurConfiguration.CustomParameters(
      blurRadius: 20,
      saturation: 1.0,
      brightness: 0.0,
      tintColor: .black,
      tintOpacity: 0.08
    )
    let blurred = image.fk_blurred(parameters: params, downsampleFactor: 2) ?? image

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 12
    row.distribution = .fillEqually

    let left = UIImageView(image: image)
    left.contentMode = .scaleAspectFill
    left.clipsToBounds = true
    left.layer.cornerRadius = 12
    left.heightAnchor.constraint(equalToConstant: 180).isActive = true

    let right = UIImageView(image: blurred)
    right.contentMode = .scaleAspectFill
    right.clipsToBounds = true
    right.layer.cornerRadius = 12
    right.heightAnchor.constraint(equalToConstant: 180).isActive = true

    row.addArrangedSubview(left)
    row.addArrangedSubview(right)

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "UIImage.fk_blurred(...)",
      description: "Left: original  |  Right: blurred (radius / saturation / brightness / tint).",
      content: row
    ))
  }

  private func makeDemoImage() -> UIImage {
    let size = CGSize(width: 600, height: 360)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      let rect = CGRect(origin: .zero, size: size)
      UIColor.systemTeal.setFill()
      ctx.fill(rect)

      let colors: [UIColor] = [.systemPink, .systemPurple, .systemBlue, .systemGreen, .systemOrange]
      for i in 0..<14 {
        colors[i % colors.count].withAlphaComponent(0.85).setFill()
        let w = size.width / 7
        let h = size.height / 2
        let x = CGFloat(i % 7) * w
        let y = (i < 7) ? 0 : h
        ctx.fill(CGRect(x: x, y: y, width: w, height: h))
      }

      let text = "FKBlurView Image Blur"
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 44),
        .foregroundColor: UIColor.white.withAlphaComponent(0.9),
      ]
      let s = NSAttributedString(string: text, attributes: attrs)
      let tSize = s.size()
      s.draw(at: CGPoint(x: (size.width - tSize.width) / 2, y: (size.height - tSize.height) / 2))
    }
  }
}

// MARK: - Scenario: UIView Snapshot Blur

fileprivate final class FKBlurUIViewSnapshotVC: FKBlurDemoBaseViewController {
  private let sourceView = FKBlurDemoUI.makeColorfulBackgroundView(height: 180)
  private let syncImageView = UIImageView()
  private let asyncImageView = UIImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIView Snapshot Blur"

    let sourceCard = FKBlurDemoUI.card(
      title: "Source UIView",
      description: "This is the live view to capture and blur.",
      content: sourceView
    )
    stack.addArrangedSubview(sourceCard)

    configurePreview(syncImageView)
    configurePreview(asyncImageView)

    let previewRow = UIStackView(arrangedSubviews: [syncImageView, asyncImageView])
    previewRow.axis = .horizontal
    previewRow.spacing = 12
    previewRow.distribution = .fillEqually

    let actions = UIStackView(arrangedSubviews: [makeSyncButton(), makeAsyncButton()])
    actions.axis = .horizontal
    actions.spacing = 10
    actions.distribution = .fillEqually

    let content = UIStackView(arrangedSubviews: [actions, previewRow])
    content.axis = .vertical
    content.spacing = 10

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "UIView+Blur",
      description: "Left preview: synchronous result. Right preview: asynchronous result.",
      content: content
    ))

    // Initial render so the page shows results immediately.
    renderSync()
    renderAsync()
  }

  private func configurePreview(_ imageView: UIImageView) {
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 12
    imageView.backgroundColor = .tertiarySystemFill
    imageView.heightAnchor.constraint(equalToConstant: 160).isActive = true
  }

  private func makeSyncButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle("Generate Sync", for: .normal)
    button.addAction(UIAction { [weak self] _ in
      self?.renderSync()
    }, for: .touchUpInside)
    return button
  }

  private func makeAsyncButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle("Generate Async", for: .normal)
    button.addAction(UIAction { [weak self] _ in
      self?.renderAsync()
    }, for: .touchUpInside)
    return button
  }

  private func renderSync() {
    let params = FKBlurConfiguration.CustomParameters(
      blurRadius: 18,
      saturation: 1.0,
      brightness: 0.0,
      tintColor: .black,
      tintOpacity: 0.08
    )
    syncImageView.image = sourceView.fk_blurredSnapshot(
      parameters: params,
      downsampleFactor: 2
    )
  }

  private func renderAsync() {
    let params = FKBlurConfiguration.CustomParameters(
      blurRadius: 22,
      saturation: 1.1,
      brightness: 0.03,
      tintColor: .systemBlue,
      tintOpacity: 0.10
    )
    asyncImageView.image = nil
    sourceView.fk_blurredSnapshotAsync(
      parameters: params,
      downsampleFactor: 2
    ) { [weak self] image in
      self?.asyncImageView.image = image
    }
  }
}

// MARK: - Scenario: Rounded / Circle / Custom Mask

fileprivate final class FKBlurRoundedRectVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rounded Rect Blur"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
    blur.maskedCornerRadius = 18 // Rounded blur region using a mask
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "cornerRadius: 18")

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "maskedCornerRadius",
      description: "Great for cards, sheets, dialogs, and overlays.",
      content: bg
    ))
  }
}

fileprivate final class FKBlurCircleVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Circular Blur"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemUltraThinMaterial))
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 120, height: 120))
    FKBlurDemoUI.addOverlayText(to: blur, text: "Circle")

    // Use maskPath for a circle (update after layout so it matches final bounds).
    blur.fk_onLayout { [weak blur] in
      guard let blur else { return }
      blur.maskPath = UIBezierPath(ovalIn: blur.bounds)
    }

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "maskPath = ovalInRect",
      description: "Great for avatar backplates and circular buttons.",
      content: bg
    ))
  }
}

fileprivate final class FKBlurCustomMaskVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Mask"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemThinMaterial))
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 220, height: 120))
    FKBlurDemoUI.addOverlayText(to: blur, text: "Arbitrary maskPath")

    // Example: a “ticket” shape (two circular notches on left and right).
    blur.fk_onLayout { [weak blur] in
      guard let blur else { return }
      let r = blur.bounds
      let notchRadius: CGFloat = 14
      let path = UIBezierPath(roundedRect: r, cornerRadius: 18)
      path.append(UIBezierPath(ovalIn: CGRect(x: -notchRadius, y: (r.height - notchRadius * 2) / 2, width: notchRadius * 2, height: notchRadius * 2)))
      path.append(UIBezierPath(ovalIn: CGRect(x: r.width - notchRadius, y: (r.height - notchRadius * 2) / 2, width: notchRadius * 2, height: notchRadius * 2)))
      blur.maskPath = path
    }

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "maskPath (arbitrary shape)",
      description: "Useful for tickets, bubbles, and custom-shaped cards.",
      content: bg
    ))
  }
}

// MARK: - Scenario: Semi-Transparent Blur

fileprivate final class FKBlurOpacityVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Semi-Transparent Blur"

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()

    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(
      backend: .system(style: .systemMaterial),
      opacity: 0.55 // Overall opacity for a lighter haze look
    )
    blur.maskedCornerRadius = 16
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "opacity: 0.55")

    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "opacity",
      description: "Control overall transparency via configuration.opacity.",
      content: bg
    ))
  }
}

// MARK: - Scenario: Global Defaults

fileprivate final class FKBlurGlobalConfigVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global Defaults"

    let apply = UIButton(type: .system)
    apply.setTitle("Apply global default (systemThinMaterial + 0.9)", for: .normal)
    apply.addAction(UIAction { _ in
      FKBlurGlobalDefaults.configuration = FKBlurConfiguration(
        backend: .system(style: .systemThinMaterial),
        opacity: 0.9
      )
    }, for: .touchUpInside)

    let create = UIButton(type: .system)
    create.setTitle("Create a FKBlurView using global default", for: .normal)
    create.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let bg = FKBlurDemoUI.makeColorfulBackgroundView(height: 130)
      let blur = FKBlurView() // Uses FKBlurGlobalDefaults.configuration as the baseline
      blur.maskedCornerRadius = 16
      FKBlurDemoUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 240, height: 74))
      FKBlurDemoUI.addOverlayText(to: blur, text: "From global default")
      self.stack.addArrangedSubview(bg)
    }, for: .touchUpInside)

    let reset = UIButton(type: .system)
    reset.setTitle("Reset global default", for: .normal)
    reset.addAction(UIAction { _ in
      FKBlurGlobalDefaults.configuration = .default
    }, for: .touchUpInside)

    let col = UIStackView(arrangedSubviews: [apply, create, reset])
    col.axis = .vertical
    col.spacing = 10
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "FKBlurGlobalDefaults.configuration",
      description: "Set once at app launch to unify style; override per view when needed.",
      content: col
    ))
  }
}

// MARK: - Scenario: Dark Mode

fileprivate final class FKBlurDarkModeVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark Mode"

    let seg = UISegmentedControl(items: ["System", "Light", "Dark"])
    seg.selectedSegmentIndex = 0
    seg.addAction(UIAction { [weak self] action in
      guard let self, let s = action.sender as? UISegmentedControl else { return }
      switch s.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let bg = FKBlurDemoUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // System materials automatically adapt to Light/Dark.
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
    blur.maskedCornerRadius = 16
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg)
    FKBlurDemoUI.addOverlayText(to: blur, text: "Switch appearance")

    let col = UIStackView(arrangedSubviews: [seg, bg])
    col.axis = .vertical
    col.spacing = 10
    stack.addArrangedSubview(FKBlurDemoUI.card(
      title: "Light / Dark",
      description: "Switch the segmented control to preview adaptive system materials.",
      content: col
    ))
  }
}

// MARK: - Scenario: Rotation

fileprivate final class FKBlurRotationVC: FKBlurDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rotation"

    let hint = UILabel()
    hint.text = "Rotate the device/simulator: the blur view will relayout (and refresh if needed)."
    hint.numberOfLines = 0
    hint.textColor = .secondaryLabel

    let bg = FKBlurDemoUI.makeColorfulBackgroundView(height: 220)
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemChromeMaterial))
    blur.maskedCornerRadius = 20
    FKBlurDemoUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 280, height: 110))
    FKBlurDemoUI.addOverlayText(to: blur, text: "Rotation-ready")

    let col = UIStackView(arrangedSubviews: [hint, bg])
    col.axis = .vertical
    col.spacing = 10
    stack.addArrangedSubview(col)
  }
}

// MARK: - Scenario: XIB / Storyboard

fileprivate final class FKBlurXIBDemoVC: UIViewController {
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

    let bg = FKBlurDemoUI.makeColorfulBackgroundView(height: 220)
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
    FKBlurDemoUI.addOverlayText(to: nibBlur, text: "Loaded from XIB")

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

// MARK: - Scenario: SwiftUI

final class FKBlurSwiftUIHostVC: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI"
    view.backgroundColor = .systemBackground

    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKBlurSwiftUIScreen())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.backgroundColor = .clear
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    #else
    let label = UILabel()
    label.text = "SwiftUI unavailable."
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKBlurSwiftUIScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        Text("FKBlurView (SwiftUI)")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        ZStack {
          RoundedRectangle(cornerRadius: 14)
            .fill(
              LinearGradient(
                colors: [.pink, .purple, .blue, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(height: 180)

          // In SwiftUI, use FKSwiftUIBlurView (UIViewRepresentable adapter).
          FKSwiftUIBlurView(
            configuration: FKBlurConfiguration(
              backend: .system(style: .systemMaterial)
            )
          )
          .frame(width: 260, height: 96)
          .clipShape(RoundedRectangle(cornerRadius: 16))

          Text("SwiftUI Blur")
            .font(.headline)
        }

        Text("Tip: for dynamic content, prefer the system backend (hardware materials). Use the custom backend only when you need full parameter control.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif

// MARK: - Scenario: Scroll Performance (60fps)

fileprivate final class FKBlurPerformanceTestVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private var fpsItem: UIBarButtonItem?
  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scroll Performance"
    view.backgroundColor = .systemBackground

    // Performance test requirement:
    // - The dynamic blur effect must be applied inside each cell.
    // - Use the system backend (hardware materials) to validate smooth 60fps scrolling under real-world usage.
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.rowHeight = 92
    tableView.separatorStyle = .none
    tableView.register(FKBlurPerformanceCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Put the FPS readout in the navigation bar so it won't affect scrolling performance.
    let fps = UIBarButtonItem(title: "FPS: --", style: .plain, target: nil, action: nil)
    fps.isEnabled = false
    navigationItem.rightBarButtonItem = fps
    fpsItem = fps

    // Optional table header with a simple hint (not blurred).
    let header = UILabel()
    header.text = "Scroll fast to validate smoothness. Each cell contains a FKBlurView (system material)."
    header.numberOfLines = 0
    header.textColor = .secondaryLabel
    header.font = .preferredFont(forTextStyle: .footnote)
    header.textAlignment = .left
    header.backgroundColor = .clear
    header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
    tableView.tableHeaderView = header
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startFPSMonitor()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopFPSMonitor()
  }

  private func startFPSMonitor() {
    guard displayLink == nil else { return }
    lastTimestamp = 0
    frameCount = 0
    let link = CADisplayLink(target: self, selector: #selector(onTick))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func stopFPSMonitor() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func onTick(link: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = link.timestamp
      return
    }
    frameCount += 1
    let delta = link.timestamp - lastTimestamp
    if delta >= 1.0 {
      let fps = Double(frameCount) / delta
      fpsItem?.title = String(format: "FPS: %.0f", fps)
      lastTimestamp = link.timestamp
      frameCount = 0
    }
  }

  // MARK: UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 200 }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? FKBlurPerformanceCell else {
      return UITableViewCell()
    }
    cell.configure(row: indexPath.row)
    return cell
  }
}

// MARK: - Cell: Blur inside each row

/// A table view cell that contains a dynamic system-material `FKBlurView`.
///
/// This cell is purposely UI-only and reuse-friendly:
/// - A vivid background makes the blur effect easy to see.
/// - The blur view is created once and reused with the cell.
fileprivate final class FKBlurPerformanceCell: UITableViewCell {
  private let card = UIView()
  private let gradient = CAGradientLayer()
  private let blurView = FKBlurView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func commonInit() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    card.translatesAutoresizingMaskIntoConstraints = false
    card.layer.cornerRadius = 14
    card.clipsToBounds = true
    contentView.addSubview(card)
    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
    ])

    gradient.colors = [
      UIColor.systemPink.cgColor,
      UIColor.systemPurple.cgColor,
      UIColor.systemBlue.cgColor,
      UIColor.systemTeal.cgColor,
    ]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    card.layer.insertSublayer(gradient, at: 0)

    // System-material backend is the highest-performance dynamic blur path.
    blurView.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
    blurView.maskedCornerRadius = 12
    blurView.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(blurView)
    NSLayoutConstraint.activate([
      blurView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
      blurView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      blurView.widthAnchor.constraint(equalToConstant: 160),
      blurView.heightAnchor.constraint(equalToConstant: 56),
    ])

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    card.addSubview(titleLabel)
    card.addSubview(subtitleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blurView.leadingAnchor, constant: -12),
      titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blurView.leadingAnchor, constant: -12),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
    ])
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Keep gradient frame in sync with the card bounds during scrolling and rotation.
    gradient.frame = card.bounds
  }

  func configure(row: Int) {
    titleLabel.text = "Row \(row)"
    subtitleLabel.text = "System material blur inside cell"
  }
}

// MARK: - Minimal layout callback helper (local)

private final class FKLayoutCallbackView: UIView {
  var onLayout: (() -> Void)?
  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

private extension UIView {
  /// Layout callback used by the demos (e.g. update gradient frames, refresh mask paths).
  func fk_onLayout(_ block: @escaping () -> Void) {
    let helper = FKLayoutCallbackView()
    helper.isUserInteractionEnabled = false
    helper.backgroundColor = .clear
    helper.onLayout = block
    helper.translatesAutoresizingMaskIntoConstraints = false
    addSubview(helper)
    NSLayoutConstraint.activate([
      helper.topAnchor.constraint(equalTo: topAnchor),
      helper.leadingAnchor.constraint(equalTo: leadingAnchor),
      helper.trailingAnchor.constraint(equalTo: trailingAnchor),
      helper.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}

