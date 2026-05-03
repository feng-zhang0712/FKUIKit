import UIKit
import FKUIKit

// MARK: - Scenario: Image Blur

final class FKBlurImageBlurVC: FKBlurExampleBaseViewController {
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

    stack.addArrangedSubview(FKBlurExampleUI.card(
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

final class FKBlurUIViewSnapshotVC: FKBlurExampleBaseViewController {
  private let sourceView = FKBlurExampleUI.makeColorfulBackgroundView(height: 180)
  private let syncImageView = UIImageView()
  private let asyncImageView = UIImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIView Snapshot Blur"

    let sourceCard = FKBlurExampleUI.card(
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

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "UIView+FKBlur",
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
