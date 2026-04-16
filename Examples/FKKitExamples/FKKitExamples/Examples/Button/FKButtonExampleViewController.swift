//
//  FKButtonExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

final class FKButtonExampleViewController: UIViewController {
  enum ExampleMetrics {
    static let inset: CGFloat = 16
    static let spacing: CGFloat = 14
    static let buttonHeight: CGFloat = 44
  }
  
  private lazy var rootStackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = ExampleMetrics.spacing
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()

  func didTapButton(_ name: String) {
    title = "FKButton · \(name)"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKButton"
    view.backgroundColor = .systemBackground
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
    ])
    scrollView.addSubview(rootStackView)
    let inset = ExampleMetrics.inset
    let contentGuide = scrollView.contentLayoutGuide
    NSLayoutConstraint.activate([
      rootStackView.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: inset),
      rootStackView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: inset),
      rootStackView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -inset),
      rootStackView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor)
    ])
    rootStackView.addArrangedSubview(sectionTitle("Text Only"))
    rootStackView.addArrangedSubview(makeTextOnlyExample())
    rootStackView.addArrangedSubview(sectionTitle("Icon Only"))
    rootStackView.addArrangedSubview(makeIconOnlyExample())
    rootStackView.addArrangedSubview(sectionTitle("Composition"))
    rootStackView.addArrangedSubview(makeCompositionExample())
    rootStackView.addArrangedSubview(sectionTitle("Vertical Layout"))
    rootStackView.addArrangedSubview(makeVerticalLayoutExample())
    rootStackView.addArrangedSubview(sectionTitle("Capsule Corner"))
    rootStackView.addArrangedSubview(makeCapsuleCornerExample())
    rootStackView.addArrangedSubview(sectionTitle("No Border"))
    rootStackView.addArrangedSubview(makeNoBorderExample())
    rootStackView.addArrangedSubview(sectionTitle("Different Length"))
    rootStackView.addArrangedSubview(makeDifferentLengthExample())
    rootStackView.addArrangedSubview(sectionTitle("Subtitle · Text Only"))
    rootStackView.addArrangedSubview(makeSubtitleTextOnlyExample())
    rootStackView.addArrangedSubview(sectionTitle("Subtitle · Text And Image"))
    rootStackView.addArrangedSubview(makeSubtitleTextAndImageExample())
    rootStackView.addArrangedSubview(sectionTitle("Subtitle · Vertical Axis"))
    rootStackView.addArrangedSubview(makeSubtitleVerticalAxisExample())
    rootStackView.addArrangedSubview(sectionTitle("Subtitle · Toggle Presence"))
    rootStackView.addArrangedSubview(makeSubtitleTogglePresenceExample())
    rootStackView.addArrangedSubview(sectionTitle("Content Kind · Cycle All"))
    rootStackView.addArrangedSubview(makeContentKindCycleAllExample())
    rootStackView.addArrangedSubview(sectionTitle("Content Kind · Picker"))
    rootStackView.addArrangedSubview(makeContentKindPickerExample())
    rootStackView.addArrangedSubview(sectionTitle("Content Kind · text ↔ custom"))
    rootStackView.addArrangedSubview(makeContentKindTextCustomPingPongExample())
    rootStackView.addArrangedSubview(sectionTitle("Content Kind · Placement Cycle"))
    rootStackView.addArrangedSubview(makeContentKindPlacementCycleExample())
    rootStackView.addArrangedSubview(sectionTitle("Content Kind · Vertical Cycle"))
    rootStackView.addArrangedSubview(makeContentKindVerticalCycleExample())
    rootStackView.setCustomSpacing(22, after: rootStackView.arrangedSubviews.last!)
  }
}

private extension FKButtonExampleViewController {
  func addTap(_ button: FKButton, name: String) {
    button.addAction(UIAction { [weak self] _ in
      self?.didTapButton(name)
    }, for: .touchUpInside)
  }

  func addTapToggleSelected(_ button: FKButton, name: String) {
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.didTapButton(name)
    }, for: .touchUpInside)
  }

  func sectionTitle(_ text: String) -> UIView {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.textAlignment = .center
    label.textColor = .label
    return label
  }
  
  struct ButtonVisualSpec {
    let foregroundColor: UIColor
    let backgroundColor: UIColor
    let borderColor: UIColor
    let shadow: FKButton.Shadow?
  }
  
  struct StatefulAppearances {
    let normal: FKButton.Appearance
    let selected: FKButton.Appearance
    let highlighted: FKButton.Appearance
    let disabled: FKButton.Appearance
    let normalForegroundColor: UIColor
    let selectedForegroundColor: UIColor
    let highlightedForegroundColor: UIColor
    let disabledForegroundColor: UIColor

    func foregroundColor(for state: UIControl.State) -> UIColor {
      switch state {
      case .selected:
        return selectedForegroundColor
      case .highlighted:
        return highlightedForegroundColor
      case .disabled:
        return disabledForegroundColor
      default:
        return normalForegroundColor
      }
    }
  }
  
  func makeStatefulAppearance(
    normal: ButtonVisualSpec,
    selected: ButtonVisualSpec,
    highlighted: ButtonVisualSpec,
    disabled: ButtonVisualSpec,
    corner: FKButton.Corner = .fixed(12),
    borderWidth: CGFloat = 1
  ) -> StatefulAppearances {
    let insets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
    func makeAppearance(from spec: ButtonVisualSpec) -> FKButton.Appearance {
      FKButton.Appearance(
        cornerStyle: .init(corner: corner),
        border: .init(width: borderWidth, color: spec.borderColor),
        backgroundColor: spec.backgroundColor,
        shadow: spec.shadow,
        contentInsets: insets
      )
    }
    return StatefulAppearances(
      normal: makeAppearance(from: normal),
      selected: makeAppearance(from: selected),
      highlighted: makeAppearance(from: highlighted),
      disabled: makeAppearance(from: disabled),
      normalForegroundColor: normal.foregroundColor,
      selectedForegroundColor: selected.foregroundColor,
      highlightedForegroundColor: highlighted.foregroundColor,
      disabledForegroundColor: disabled.foregroundColor
    )
  }
}

private extension FKButtonExampleViewController {
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
      self?.didTapButton("TextOnly: Normal")
    }, for: .touchUpInside)
    selectedBtn.addAction(UIAction { [weak self, weak selectedBtn] _ in
      selectedBtn?.isSelected.toggle()
      self?.didTapButton("TextOnly: Selected")
    }, for: .touchUpInside)
    highlightedBtn.addAction(UIAction { [weak self] _ in
      self?.didTapButton("TextOnly: Highlighted")
    }, for: .touchUpInside)
    stack.addArrangedSubview(normalBtn)
    stack.addArrangedSubview(selectedBtn)
    stack.addArrangedSubview(highlightedBtn)
    stack.addArrangedSubview(disabledBtn)
    NSLayoutConstraint.activate([
      normalBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      selectedBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      highlightedBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      disabledBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight)
    ])
    return stack
  }
  
  func makeTextButton(
    title: String,
    appearances: StatefulAppearances
  ) -> FKButton {
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
      self?.didTapButton("IconOnly: Selected")
    }, for: .touchUpInside)
    stack.addArrangedSubview(normalBtn)
    stack.addArrangedSubview(selectedBtn)
    stack.addArrangedSubview(disabledBtn)
    NSLayoutConstraint.activate([
      normalBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      selectedBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      disabledBtn.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight)
    ])
    return stack
  }
  
  func makeIconButton(
    systemName: String,
    appearances: StatefulAppearances
  ) -> FKButton {
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
      leading.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      both.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      trailing.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight),
      disabled.heightAnchor.constraint(equalToConstant: ExampleMetrics.buttonHeight)
    ])
    return stack
  }
}
