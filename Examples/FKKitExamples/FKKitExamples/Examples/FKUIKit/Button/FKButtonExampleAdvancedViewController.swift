import UIKit
import FKUIKit

final class FKButtonExampleAdvancedViewController: FKButtonExampleBaseViewController {
  override var pageExplanationText: String? {
    "Advanced examples cover global defaults and Interface Builder attributes."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleSection(title: "GlobalStyle snapshot", content: makeGlobalStyleSnapshotExample())
    addExampleSection(title: "Storyboard / XIB", content: makeStoryboardAttributesHint())
  }

  private func makeGlobalStyleSnapshotExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    let host = UIStackView()
    host.axis = .vertical
    host.alignment = .center
    host.spacing = 8

    let trigger = UIButton(type: .system)
    trigger.setTitle("Instantiate FKButton() with template GlobalStyle", for: .normal)
    trigger.titleLabel?.numberOfLines = 0
    trigger.titleLabel?.textAlignment = .center
    trigger.addAction(UIAction { [weak self] _ in
      let previous = FKButton.GlobalStyle.defaultAppearances
      FKButton.GlobalStyle.defaultAppearances = Self.templateStateAppearancesForGlobalStyleExample()
      let b = FKButton()
      b.content = .init(kind: .textOnly)
      b.setTitle(.init(text: "From GlobalStyle", font: .systemFont(ofSize: 14, weight: .semibold), color: .white), for: .normal)
      FKButton.GlobalStyle.defaultAppearances = previous
      b.heightAnchor.constraint(equalToConstant: 44).isActive = true
      b.widthAnchor.constraint(equalToConstant: 220).isActive = true
      self?.addTap(b, name: "GlobalStyle snapshot")
      host.arrangedSubviews.forEach { if $0 is FKButton { $0.removeFromSuperview() } }
      host.addArrangedSubview(b)
    }, for: .touchUpInside)

    stack.addArrangedSubview(captionLabel("Snapshot, override, create, then restore to avoid leaking defaults globally."))
    stack.addArrangedSubview(fullWidthLayoutWrapping(trigger))
    stack.addArrangedSubview(horizontallyCentered(host))
    return stack
  }

  private func makeStoryboardAttributesHint() -> UIView {
    captionLabel("Storyboard/XIB: set class to FKButton, then configure `fk_` inspectables in Interface Builder.")
  }

  private static func templateStateAppearancesForGlobalStyleExample() -> FKButton.StateAppearances {
    let normal = FKButton.Appearance(cornerStyle: .init(corner: .capsule), border: .init(width: 0, color: .clear), backgroundColor: .systemGreen)
    let selected = FKButton.Appearance(cornerStyle: .init(corner: .capsule), border: .init(width: 0, color: .clear), backgroundColor: .systemMint)
    return .init(normal: normal, selected: selected, highlighted: selected, disabled: normal.merged(with: .init(alpha: 0.45)))
  }
}
