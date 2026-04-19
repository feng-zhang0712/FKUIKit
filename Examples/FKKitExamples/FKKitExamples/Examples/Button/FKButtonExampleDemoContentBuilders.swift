//
//  FKButtonExampleDemoContentBuilders.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

extension FKButtonExampleBaseViewController {

  func makeTextOnlyStatefulAppearances(highlightedForegroundColor: UIColor) -> StatefulAppearances {
    makeStatefulAppearance(
      normal: ButtonVisualSpec(
        foregroundColor: .label,
        backgroundColor: .clear,
        borderColor: .clear,
        shadow: nil
      ),
      selected: ButtonVisualSpec(
        foregroundColor: .systemBlue,
        backgroundColor: .clear,
        borderColor: .clear,
        shadow: nil
      ),
      highlighted: ButtonVisualSpec(
        foregroundColor: highlightedForegroundColor,
        backgroundColor: .clear,
        borderColor: .clear,
        shadow: nil
      ),
      disabled: ButtonVisualSpec(
        foregroundColor: .secondaryLabel,
        backgroundColor: .clear,
        borderColor: .clear,
        shadow: nil
      ),
      corner: .none,
      borderWidth: 0
    )
  }

  func makeTextOnlyExample() -> UIView {
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
    normalBtn.addAction(UIAction { [weak self] _ in
      self?.recordDemoTap("TextOnly: Normal")
    }, for: .touchUpInside)
    selectedBtn.addAction(UIAction { [weak self, weak selectedBtn] _ in
      selectedBtn?.isSelected.toggle()
      self?.recordDemoTap("TextOnly: Selected")
    }, for: .touchUpInside)
    highlightedBtn.addAction(UIAction { [weak self] _ in
      self?.recordDemoTap("TextOnly: Highlighted")
    }, for: .touchUpInside)
    stack.addArrangedSubview(normalBtn)
    stack.addArrangedSubview(selectedBtn)
    stack.addArrangedSubview(highlightedBtn)
    stack.addArrangedSubview(disabledBtn)
    NSLayoutConstraint.activate([
      normalBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      selectedBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      highlightedBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      disabledBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
    ])
    return stack
  }

  func makeTextButton(title: String, appearances: StatefulAppearances) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .textOnly)
    [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
      button.setTitle(
        .init(
          text: title,
          font: .systemFont(ofSize: 15, weight: .semibold),
          color: appearances.foregroundColor(for: state)
        ),
        for: state
      )
    }
    button.setAppearance(appearances.normal, for: .normal)
    button.setAppearance(appearances.selected, for: .selected)
    button.setAppearance(appearances.highlighted, for: .highlighted)
    button.setAppearance(appearances.disabled, for: .disabled)
    return button
  }

  func makeIconOnlyExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    let appearances = makeStatefulAppearance(
      normal: ButtonVisualSpec(
        foregroundColor: .label,
        backgroundColor: .tertiarySystemBackground,
        borderColor: .separator,
        shadow: nil
      ),
      selected: ButtonVisualSpec(
        foregroundColor: .white,
        backgroundColor: .systemGreen,
        borderColor: .systemGreen,
        shadow: FKButton.Shadow(color: .systemGreen, opacity: 0.18, offset: CGSize(width: 0, height: 3), radius: 6)
      ),
      highlighted: ButtonVisualSpec(
        foregroundColor: .white,
        backgroundColor: .systemGreen,
        borderColor: .systemGreen,
        shadow: FKButton.Shadow(color: .systemGreen, opacity: 0.18, offset: CGSize(width: 0, height: 3), radius: 6)
      ),
      disabled: ButtonVisualSpec(
        foregroundColor: .secondaryLabel,
        backgroundColor: .systemGray6,
        borderColor: .tertiarySystemFill,
        shadow: nil
      )
    )
    let normalBtn = makeIconButton(systemName: "star.fill", appearances: appearances)
    let selectedBtn = makeIconButton(systemName: "star.fill", appearances: appearances)
    selectedBtn.isSelected = true
    let disabledBtn = makeIconButton(systemName: "star.fill", appearances: appearances)
    disabledBtn.isEnabled = false
    addTap(normalBtn, name: "IconOnly: Normal")
    selectedBtn.addAction(UIAction { [weak self, weak selectedBtn] _ in
      selectedBtn?.isSelected.toggle()
      self?.recordDemoTap("IconOnly: Selected")
    }, for: .touchUpInside)
    stack.addArrangedSubview(normalBtn)
    stack.addArrangedSubview(selectedBtn)
    stack.addArrangedSubview(disabledBtn)
    NSLayoutConstraint.activate([
      normalBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      selectedBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      disabledBtn.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
    ])
    return stack
  }

  func makeIconButton(systemName: String, appearances: StatefulAppearances) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .imageOnly)
    [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
      button.setImage(
        .init(
          image: UIImage(systemName: systemName),
          tintColor: appearances.foregroundColor(for: state)
        ),
        for: state
      )
    }
    button.setAppearance(appearances.normal, for: .normal)
    button.setAppearance(appearances.selected, for: .selected)
    button.setAppearance(appearances.highlighted, for: .highlighted)
    button.setAppearance(appearances.disabled, for: .disabled)
    button.accessibilityLabel = systemName
    return button
  }

  func makeCompositionAppearances() -> StatefulAppearances {
    makeStatefulAppearance(
      normal: ButtonVisualSpec(
        foregroundColor: .label,
        backgroundColor: .tertiarySystemBackground,
        borderColor: .separator,
        shadow: nil
      ),
      selected: ButtonVisualSpec(
        foregroundColor: .white,
        backgroundColor: .systemOrange,
        borderColor: .systemOrange,
        shadow: FKButton.Shadow(
          color: .systemOrange,
          opacity: 0.2,
          offset: CGSize(width: 0, height: 3),
          radius: 6
        )
      ),
      highlighted: ButtonVisualSpec(
        foregroundColor: .white,
        backgroundColor: .systemOrange,
        borderColor: .systemOrange,
        shadow: FKButton.Shadow(color: .systemOrange, opacity: 0.2, offset: CGSize(width: 0, height: 3), radius: 6)
      ),
      disabled: ButtonVisualSpec(
        foregroundColor: .secondaryLabel,
        backgroundColor: .systemGray6,
        borderColor: .tertiarySystemFill,
        shadow: nil
      )
    )
  }

  func makeCompositionButton(
    content: FKButton.Content,
    title: String,
    leadingSystemName: String? = nil,
    trailingSystemName: String? = nil,
    appearances: StatefulAppearances,
    isSelected: Bool = false,
    isEnabled: Bool = true
  ) -> FKButton {
    let button = FKButton()
    button.content = content
    button.isEnabled = isEnabled
    [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
      button.setTitle(
        .init(
          text: title,
          font: .systemFont(ofSize: 15, weight: .semibold),
          color: appearances.foregroundColor(for: state)
        ),
        for: state
      )
    }
    if let leadingSystemName {
      [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
        button.setLeadingImage(
          .init(
            image: UIImage(systemName: leadingSystemName),
            tintColor: appearances.foregroundColor(for: state)
          ),
          for: state
        )
      }
    }
    if let trailingSystemName {
      [UIControl.State.normal, .selected, .highlighted, .disabled].forEach { state in
        button.setTrailingImage(
          .init(
            image: UIImage(systemName: trailingSystemName),
            tintColor: appearances.foregroundColor(for: state)
          ),
          for: state
        )
      }
    }
    if isEnabled {
      button.setAppearance(appearances.normal, for: .normal)
      button.setAppearance(appearances.selected, for: .selected)
      button.setAppearance(appearances.highlighted, for: .highlighted)
      button.isSelected = isSelected
    } else {
      button.setAppearance(appearances.disabled, for: .disabled)
    }
    return button
  }

  func makeCompositionExample() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    let appearances = makeCompositionAppearances()
    let leading = makeCompositionButton(
      content: .init(kind: .textAndImage(.leading)),
      title: "Leading",
      leadingSystemName: "paperplane.fill",
      appearances: appearances
    )
    let both = makeCompositionButton(
      content: .init(kind: .textAndImage(.bothSides)),
      title: "Both",
      leadingSystemName: "chevron.left",
      trailingSystemName: "chevron.right",
      appearances: appearances,
      isSelected: true
    )
    let trailing = makeCompositionButton(
      content: .init(kind: .textAndImage(.trailing)),
      title: "Trailing",
      trailingSystemName: "arrow.forward.circle.fill",
      appearances: appearances
    )
    let disabled = makeCompositionButton(
      content: .init(kind: .textAndImage(.bothSides)),
      title: "Disabled",
      leadingSystemName: "lock.fill",
      trailingSystemName: "lock.fill",
      appearances: appearances,
      isEnabled: false
    )
    addTap(leading, name: "Composition: Leading")
    addTapToggleSelected(both, name: "Composition: Both")
    addTap(trailing, name: "Composition: Trailing")
    stack.addArrangedSubview(leading)
    stack.addArrangedSubview(both)
    stack.addArrangedSubview(trailing)
    stack.addArrangedSubview(disabled)
    NSLayoutConstraint.activate([
      leading.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      both.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      trailing.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
      disabled.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
    ])
    return stack
  }
}
