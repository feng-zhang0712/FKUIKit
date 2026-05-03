import UIKit
import FKUIKit

// MARK: - Shared Demo UI Helpers

enum FKBlurExampleUI {
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

class FKBlurExampleBaseViewController: UIViewController {
  var stack: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    stack = FKBlurExampleUI.makeScrollStack(in: self)
  }
}
// MARK: - Minimal layout callback helper (local)

final class FKLayoutCallbackView: UIView {
  var onLayout: (() -> Void)?
  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

extension UIView {
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
