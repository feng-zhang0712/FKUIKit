import UIKit
import FKUIKit

final class FKButtonExampleAppearanceViewController: FKButtonExampleBaseViewController {
  override var pageExplanationText: String? {
    "Appearance examples cover gradients, highlight feedback tuning, disabled dimming, and image/title spacing."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleSection(title: "Gradient", content: makeGradientExample())
    addExampleSection(title: "Disabled dimming", content: makeDisabledDimmingExample())
    addExampleSection(title: "Image ↔ title spacing", content: makeImageTitleSpacingExample())
  }

  private func makeGradientExample() -> UIView {
    let g = FKButtonLinearGradient(colors: [.systemPurple, .systemBlue], startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
    let b = FKButton()
    b.content = .init(kind: .textOnly)
    b.setTitle(.init(text: "Gradient button", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    b.setAppearances(.init(normal: .init(cornerStyle: .init(corner: .fixed(14)), border: .init(width: 1, color: UIColor.white.withAlphaComponent(0.35)), backgroundColor: .clear, backgroundGradient: g)))
    b.heightAnchor.constraint(equalToConstant: 48).isActive = true
    b.widthAnchor.constraint(equalToConstant: 260).isActive = true
    addTap(b, name: "Appearance gradient")
    let stack = UIStackView(arrangedSubviews: [captionLabel("Gradient, border, and corner style can be composed per state."), horizontallyCentered(b)])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }

  private func makeDisabledDimmingExample() -> UIView {
    let dimmed = FKButton()
    dimmed.content = .init(kind: .textOnly)
    dimmed.setTitle(.init(text: "Dimmed (default)", font: .systemFont(ofSize: 14, weight: .semibold), color: .label), for: .normal)
    dimmed.setAppearances(.init(normal: .filled(backgroundColor: .systemGray5, cornerStyle: .init(corner: .fixed(10)))))
    dimmed.isEnabled = false
    dimmed.automaticallyDimsWhenDisabled = true
    dimmed.disabledDimmingAlpha = 0.5

    let raw = FKButton()
    raw.content = .init(kind: .textOnly)
    raw.setTitle(.init(text: "Not dimmed", font: .systemFont(ofSize: 14, weight: .semibold), color: .label), for: .normal)
    raw.setAppearances(.init(normal: .filled(backgroundColor: .systemGray5, cornerStyle: .init(corner: .fixed(10)))))
    raw.isEnabled = false
    raw.automaticallyDimsWhenDisabled = false

    [dimmed, raw].forEach {
      $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 220).isActive = true
    }
    let stack = UIStackView(arrangedSubviews: [captionLabel("`automaticallyDimsWhenDisabled` controls disabled alpha behavior."), horizontallyCentered(dimmed), horizontallyCentered(raw)])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }

  private func makeImageTitleSpacingExample() -> UIView {
    func row(spacing: CGFloat, label: String) -> FKButton {
      let b = FKButton()
      b.content = .init(kind: .textAndImage(.leading))
      b.setTitle(.init(text: label, font: .systemFont(ofSize: 14, weight: .semibold), color: .label), for: .normal)
      b.setImage(.init(systemName: "star.fill", tintColor: .systemYellow, fixedSize: CGSize(width: 22, height: 22), spacingToTitle: spacing), slot: .leading, for: .normal)
      b.setAppearances(.init(normal: .init(cornerStyle: .init(corner: .fixed(10)), border: .init(width: 1, color: .separator), backgroundColor: .tertiarySystemBackground)))
      b.heightAnchor.constraint(equalToConstant: 44).isActive = true
      b.widthAnchor.constraint(equalToConstant: 260).isActive = true
      return b
    }
    let stack = UIStackView(arrangedSubviews: [
      captionLabel("`spacingToTitle` controls image-title gap in stack layout."),
      horizontallyCentered(row(spacing: 4, label: "spacingToTitle = 4")),
      horizontallyCentered(row(spacing: 20, label: "spacingToTitle = 20")),
    ])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }
}
