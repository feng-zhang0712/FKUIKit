import UIKit
import FKUIKit

final class FKButtonExampleLayoutViewController: FKButtonExampleBaseViewController {
  override var pageExplanationText: String? {
    "Layout examples focus on axis, corner style, subtitle, and content insets."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleSection(title: "Vertical layout", content: makeVerticalLayoutExample())
    addExampleSection(title: "Capsule corner", content: makeCapsuleCornerExample())
    addExampleSection(title: "Different width", content: makeDifferentLengthExample())
    addExampleSection(title: "Subtitle", content: makeSubtitleExample())
  }

  private func makeVerticalLayoutExample() -> UIView {
    let b = FKButton()
    b.content = .init(kind: .textAndImage(.leading))
    b.axis = .vertical
    b.setTitle(.init(text: "Upload", font: .systemFont(ofSize: 14, weight: .semibold), color: .label), for: .normal)
    b.setCenterImage(.init(systemName: "arrow.up.circle.fill", tintColor: .systemBlue, spacingToTitle: 8), for: .normal)
    b.setAppearances(.init(normal: .init(cornerStyle: .init(corner: .fixed(12)), border: .init(width: 1, color: .separator), backgroundColor: .tertiarySystemBackground)))
    b.heightAnchor.constraint(equalToConstant: 88).isActive = true
    b.widthAnchor.constraint(equalToConstant: 180).isActive = true
    addTap(b, name: "Layout vertical")
    let stack = UIStackView(arrangedSubviews: [captionLabel("`axis = .vertical` stacks image and title vertically."), horizontallyCentered(b)])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }

  private func makeCapsuleCornerExample() -> UIView {
    let b = FKButton()
    b.content = .init(kind: .textOnly)
    b.setTitle(.init(text: "Capsule corner", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    b.setAppearances(.init(normal: .filled(backgroundColor: .systemBlue, cornerStyle: .init(corner: .capsule))))
    b.heightAnchor.constraint(equalToConstant: 44).isActive = true
    b.widthAnchor.constraint(equalToConstant: 220).isActive = true
    addTap(b, name: "Layout capsule")
    let stack = UIStackView(arrangedSubviews: [captionLabel("Capsule corner auto tracks current height."), horizontallyCentered(b)])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }

  private func makeDifferentLengthExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    ["Short", "A much longer button title"].forEach { text in
      let b = FKButton()
      b.content = .init(kind: .textOnly)
      b.setTitle(.init(text: text, font: .systemFont(ofSize: 14, weight: .medium), color: .label), for: .normal)
      b.setAppearances(.init(normal: .init(cornerStyle: .init(corner: .fixed(10)), border: .init(width: 1, color: .separator), backgroundColor: .tertiarySystemBackground)))
      b.heightAnchor.constraint(equalToConstant: 44).isActive = true
      addTap(b, name: "Layout width")
      stack.addArrangedSubview(horizontallyCentered(b))
    }
    let host = UIStackView(arrangedSubviews: [captionLabel("Intrinsic width follows text length while preserving fixed height."), stack])
    host.axis = .vertical
    host.spacing = 10
    return host
  }

  private func makeSubtitleExample() -> UIView {
    let b = FKButton()
    b.content = .init(kind: .textOnly)
    b.setTitle(.init(text: "Title", font: .systemFont(ofSize: 15, weight: .semibold), color: .label), for: .normal)
    b.setSubtitle(.init(text: "Subtitle text", font: .systemFont(ofSize: 12, weight: .regular), color: .secondaryLabel), for: .normal)
    b.setAppearances(.init(normal: .init(cornerStyle: .init(corner: .fixed(12)), border: .init(width: 1, color: .separator), backgroundColor: .tertiarySystemBackground, contentInsets: .init(top: 10, leading: 14, bottom: 10, trailing: 14))))
    b.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
    b.widthAnchor.constraint(equalToConstant: 240).isActive = true
    addTap(b, name: "Layout subtitle")
    let stack = UIStackView(arrangedSubviews: [captionLabel("Subtitle participates in accessibility value and adaptive layout."), horizontallyCentered(b)])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }
}
