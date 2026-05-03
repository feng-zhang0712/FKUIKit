import UIKit
import FKUIKit

final class FKButtonExampleLayoutViewController: FKButtonExampleScrollViewController {

  override var pageIntroduction: String? {
    "Layout examples focus on axis, corner style, subtitle, and content insets."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleCategory(
      title: "Geometry & sizing",
      description: "How axis, corner behavior, width fitting, and subtitle sizing affect layout."
    )
    addExampleSection(title: "Vertical layout", content: makeVerticalLayoutExample())
    addExampleSection(title: "Capsule corner", content: makeCapsuleCornerExample())
    addExampleSection(title: "Different width", content: makeDifferentLengthExample())
    addExampleSection(title: "Subtitle", content: makeSubtitleExample())

    addExampleCategory(
      title: "Compound content",
      description: "Mixed content layouts using both-side images with center content."
    )
    addExampleSection(
      title: "Leading + trailing image + center title/subtitle",
      content: makeBothSideImagesWithTitleSubtitleExample()
    )
    addExampleSection(
      title: "Leading + center + trailing image",
      content: makeThreeImagesInCenterExample()
    )
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
    b.heightAnchor.constraint(equalToConstant: FKButtonExampleSupport.Metrics.buttonHeight).isActive = true
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
      b.heightAnchor.constraint(equalToConstant: FKButtonExampleSupport.Metrics.buttonHeight).isActive = true
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

  private func makeBothSideImagesWithTitleSubtitleExample() -> UIView {
    let b = FKButton()
    b.content = .init(kind: .textAndImage(.bothSides))
    b.setTitle(.init(text: "Transfer", font: .systemFont(ofSize: 15, weight: .semibold), color: .label), for: .normal)
    b.setSubtitle(.init(text: "2 files pending", font: .systemFont(ofSize: 12, weight: .regular), color: .secondaryLabel), for: .normal)
    b.setLeadingImage(.init(systemName: "arrow.left.circle.fill", tintColor: .systemBlue, spacingToTitle: 10), for: .normal)
    b.setTrailingImage(.init(systemName: "arrow.right.circle.fill", tintColor: .systemGreen, spacingToTitle: 10), for: .normal)
    b.setAppearances(
      .init(
        normal: .init(
          cornerStyle: .init(corner: .fixed(12)),
          border: .init(width: 1, color: .separator),
          backgroundColor: .tertiarySystemBackground,
          contentInsets: .init(top: 10, leading: 14, bottom: 10, trailing: 14)
        )
      )
    )
    b.widthAnchor.constraint(equalToConstant: 290).isActive = true
    b.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
    addTap(b, name: "Layout both-side with title/subtitle")

    let stack = UIStackView(
      arrangedSubviews: [
        captionLabel("Both-side image slots with center title/subtitle for dense list actions."),
        horizontallyCentered(b),
      ]
    )
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }

  private func makeThreeImagesInCenterExample() -> UIView {
    let b = FKButton()
    b.content = .init(kind: .custom)

    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    row.isUserInteractionEnabled = false
    ["chevron.left.circle.fill", "camera.circle.fill", "chevron.right.circle.fill"].forEach { name in
      let iv = UIImageView(image: UIImage(systemName: name))
      iv.tintColor = .systemIndigo
      iv.contentMode = .scaleAspectFit
      iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
      iv.heightAnchor.constraint(equalToConstant: 22).isActive = true
      row.addArrangedSubview(iv)
    }

    b.setCustomContent(.init(view: row), for: .normal)
    b.setAppearances(
      .init(
        normal: .init(
          cornerStyle: .init(corner: .fixed(12)),
          border: .init(width: 1, color: .separator),
          backgroundColor: .tertiarySystemBackground,
          contentInsets: .init(top: 10, leading: 14, bottom: 10, trailing: 14)
        )
      )
    )
    b.widthAnchor.constraint(equalToConstant: 230).isActive = true
    b.heightAnchor.constraint(equalToConstant: 52).isActive = true
    addTap(b, name: "Layout three-image center row")

    let stack = UIStackView(
      arrangedSubviews: [
        captionLabel("Custom content mode can render leading + center + trailing images in one row."),
        horizontallyCentered(b),
      ]
    )
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }
}
