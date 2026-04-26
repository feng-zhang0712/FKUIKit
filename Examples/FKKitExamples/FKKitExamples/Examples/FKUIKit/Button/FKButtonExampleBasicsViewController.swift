import UIKit
import FKUIKit

final class FKButtonExampleBasicsViewController: FKButtonExampleBaseViewController {
  override var pageExplanationText: String? {
    "Basics examples focus on content kinds (text only / image only / text+image) and stateful styling."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleCategory(
      title: "Text-focused examples",
      description: "Demonstrates text rendering, state transitions, and text+image composition."
    )
    addExampleSection(title: "Text only", content: makeTextOnlyExample())
    addExampleSection(title: "Composition", content: makeCompositionExample())

    addExampleCategory(
      title: "Image-focused examples",
      description: "Demonstrates image-only visuals and stateful icon styling."
    )
    addExampleSection(title: "Icon only", content: makeIconOnlyExample())
  }

  private func makeTextOnlyStatefulAppearances(highlightedForegroundColor: UIColor) -> StatefulAppearances {
    makeStatefulAppearance(
      normal: .init(foregroundColor: .label, backgroundColor: .clear, borderColor: .clear, shadow: nil),
      selected: .init(foregroundColor: .systemBlue, backgroundColor: .clear, borderColor: .clear, shadow: nil),
      highlighted: .init(foregroundColor: highlightedForegroundColor, backgroundColor: .clear, borderColor: .clear, shadow: nil),
      disabled: .init(foregroundColor: .secondaryLabel, backgroundColor: .clear, borderColor: .clear, shadow: nil),
      corner: .none,
      borderWidth: 0
    )
  }

  private func makeTextOnlyExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    let normalAppearances = makeTextOnlyStatefulAppearances(highlightedForegroundColor: .systemBlue)
    let highlightedAppearances = makeTextOnlyStatefulAppearances(highlightedForegroundColor: .systemIndigo)
    let normalBtn = makeTextButton(title: "Normal", appearances: normalAppearances)
    let selectedBtn = makeTextButton(title: "Selected", appearances: normalAppearances)
    selectedBtn.isSelected = true
    let highlightedBtn = makeTextButton(title: "Highlighted", appearances: highlightedAppearances)
    let disabledBtn = makeTextButton(title: "Disabled", appearances: normalAppearances)
    disabledBtn.isEnabled = false
    addTap(normalBtn, name: "TextOnly: Normal")
    selectedBtn.addAction(UIAction { [weak self, weak selectedBtn] _ in
      selectedBtn?.isSelected.toggle()
      self?.recordExampleTap("TextOnly: Selected")
    }, for: .touchUpInside)
    addTap(highlightedBtn, name: "TextOnly: Highlighted")
    [normalBtn, selectedBtn, highlightedBtn, disabledBtn].forEach {
      $0.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight).isActive = true
      stack.addArrangedSubview($0)
    }
    return stack
  }

  private func makeTextButton(title: String, appearances: StatefulAppearances) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .textOnly)
    [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
      button.setTitle(.init(text: title, font: .systemFont(ofSize: 15, weight: .semibold), color: appearances.foregroundColor(for: state)), for: state)
    }
    button.setAppearance(appearances.normal, for: .normal)
    button.setAppearance(appearances.selected, for: .selected)
    button.setAppearance(appearances.highlighted, for: .highlighted)
    button.setAppearance(appearances.disabled, for: .disabled)
    return button
  }

  private func makeIconOnlyExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    let appearances = makeStatefulAppearance(
      normal: .init(foregroundColor: .label, backgroundColor: .tertiarySystemBackground, borderColor: .separator, shadow: nil),
      selected: .init(foregroundColor: .white, backgroundColor: .systemGreen, borderColor: .systemGreen, shadow: .init(color: .systemGreen, opacity: 0.18, offset: CGSize(width: 0, height: 3), radius: 6)),
      highlighted: .init(foregroundColor: .white, backgroundColor: .systemGreen, borderColor: .systemGreen, shadow: .init(color: .systemGreen, opacity: 0.18, offset: CGSize(width: 0, height: 3), radius: 6)),
      disabled: .init(foregroundColor: .secondaryLabel, backgroundColor: .systemGray6, borderColor: .tertiarySystemFill, shadow: nil)
    )
    let normalBtn = makeIconButton(systemName: "star.fill", appearances: appearances)
    let selectedBtn = makeIconButton(systemName: "star.fill", appearances: appearances)
    selectedBtn.isSelected = true
    let disabledBtn = makeIconButton(systemName: "star.fill", appearances: appearances)
    disabledBtn.isEnabled = false
    addTap(normalBtn, name: "IconOnly: Normal")
    selectedBtn.addAction(UIAction { [weak self, weak selectedBtn] _ in
      selectedBtn?.isSelected.toggle()
      self?.recordExampleTap("IconOnly: Selected")
    }, for: .touchUpInside)
    [normalBtn, selectedBtn, disabledBtn].forEach {
      $0.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight).isActive = true
      stack.addArrangedSubview($0)
    }
    return stack
  }

  private func makeIconButton(systemName: String, appearances: StatefulAppearances) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .imageOnly)
    [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
      button.setImage(.init(image: UIImage(systemName: systemName), tintColor: appearances.foregroundColor(for: state)), slot: .center, for: state)
    }
    button.setAppearance(appearances.normal, for: .normal)
    button.setAppearance(appearances.selected, for: .selected)
    button.setAppearance(appearances.highlighted, for: .highlighted)
    button.setAppearance(appearances.disabled, for: .disabled)
    button.accessibilityLabel = systemName
    return button
  }

  private func makeCompositionExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    let appearances = makeStatefulAppearance(
      normal: .init(foregroundColor: .label, backgroundColor: .tertiarySystemBackground, borderColor: .separator, shadow: nil),
      selected: .init(foregroundColor: .white, backgroundColor: .systemOrange, borderColor: .systemOrange, shadow: .init(color: .systemOrange, opacity: 0.2, offset: CGSize(width: 0, height: 3), radius: 6)),
      highlighted: .init(foregroundColor: .white, backgroundColor: .systemOrange, borderColor: .systemOrange, shadow: .init(color: .systemOrange, opacity: 0.2, offset: CGSize(width: 0, height: 3), radius: 6)),
      disabled: .init(foregroundColor: .secondaryLabel, backgroundColor: .systemGray6, borderColor: .tertiarySystemFill, shadow: nil)
    )
    let leading = makeCompositionButton(title: "Leading", kind: .textAndImage(.leading), leading: "paperplane.fill", trailing: nil, appearances: appearances)
    let both = makeCompositionButton(title: "Both", kind: .textAndImage(.bothSides), leading: "chevron.left", trailing: "chevron.right", appearances: appearances)
    both.isSelected = true
    let trailing = makeCompositionButton(title: "Trailing", kind: .textAndImage(.trailing), leading: nil, trailing: "arrow.forward.circle.fill", appearances: appearances)
    let disabled = makeCompositionButton(title: "Disabled", kind: .textAndImage(.bothSides), leading: "lock.fill", trailing: "lock.fill", appearances: appearances)
    disabled.isEnabled = false
    addTap(leading, name: "Composition: Leading")
    addTapToggleSelected(both, name: "Composition: Both")
    addTap(trailing, name: "Composition: Trailing")
    [leading, both, trailing, disabled].forEach {
      $0.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight).isActive = true
      stack.addArrangedSubview($0)
    }
    return stack
  }

  private func makeCompositionButton(
    title: String,
    kind: FKButton.Content.Kind,
    leading: String?,
    trailing: String?,
    appearances: StatefulAppearances
  ) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: kind)
    [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
      let color = appearances.foregroundColor(for: state)
      button.setTitle(.init(text: title, font: .systemFont(ofSize: 15, weight: .semibold), color: color), for: state)
      if let leading { button.setImage(.init(image: UIImage(systemName: leading), tintColor: color), slot: .leading, for: state) }
      if let trailing { button.setImage(.init(image: UIImage(systemName: trailing), tintColor: color), slot: .trailing, for: state) }
    }
    button.setAppearance(appearances.normal, for: .normal)
    button.setAppearance(appearances.selected, for: .selected)
    button.setAppearance(appearances.highlighted, for: .highlighted)
    button.setAppearance(appearances.disabled, for: .disabled)
    return button
  }
}
