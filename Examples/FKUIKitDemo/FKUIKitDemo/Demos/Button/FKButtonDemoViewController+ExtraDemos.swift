//
//  FKButtonDemoViewController+ExtraDemos.swift
//  FKUIKitDemo
//

import UIKit
import FKButton

extension FKButtonDemoViewController {
  
  private struct AppearanceSpec {
    let foregroundColor: UIColor
    let backgroundColor: UIColor
    let borderColor: UIColor
    let borderWidth: CGFloat
    let corner: FKButton.Corner
    let shadow: FKButton.Shadow?
  }
  
  private func makeAppearance(from spec: AppearanceSpec) -> FKButton.Appearance {
    FKButton.Appearance(
      cornerStyle: .init(corner: spec.corner),
      border: .init(width: spec.borderWidth, color: spec.borderColor),
      backgroundColor: spec.backgroundColor,
      shadow: spec.shadow,
      contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
    )
  }

  private func setStatefulTitle(
    _ text: String,
    on button: FKButton,
    normal: AppearanceSpec,
    selected: AppearanceSpec
  ) {
    button.setTitle(.init(text: text, color: normal.foregroundColor), for: .normal)
    button.setTitle(.init(text: text, color: selected.foregroundColor), for: .selected)
    button.setTitle(.init(text: text, color: selected.foregroundColor), for: .highlighted)
    button.setTitle(.init(text: text, color: .secondaryLabel), for: .disabled)
  }

  private func setStatefulImage(
    _ image: UIImage?,
    on button: FKButton,
    normal: AppearanceSpec,
    selected: AppearanceSpec,
    position: FKButton.Content.ImagePlacement? = nil
  ) {
    let normalImage = FKButton.Image(image: image, tintColor: normal.foregroundColor)
    let selectedImage = FKButton.Image(image: image, tintColor: selected.foregroundColor)
    let disabledImage = FKButton.Image(image: image, tintColor: .secondaryLabel)

    func set(_ element: FKButton.Image, for state: UIControl.State) {
      if let position {
        switch position {
        case .leading:
          button.setLeadingImage(element, for: state)
        case .trailing:
          button.setTrailingImage(element, for: state)
        case .bothSides:
          button.setLeadingImage(element, for: state)
          button.setTrailingImage(element, for: state)
        }
      } else {
        button.setImage(element, for: state)
      }
    }

    set(normalImage, for: .normal)
    set(selectedImage, for: .selected)
    set(selectedImage, for: .highlighted)
    set(disabledImage, for: .disabled)
  }
  
  func makeVerticalLayoutDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .tertiarySystemBackground,
      borderColor: .separator,
      borderWidth: 1,
      corner: .fixed(12),
      shadow: nil
    )

    let selectedSpec = AppearanceSpec(
      foregroundColor: .systemBlue,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .none,
      shadow: nil
    )
    
    let textOnly = makeVerticalTextOnlyButton(normal: normalSpec, selected: selectedSpec)
    let iconOnly = makeVerticalIconOnlyButton(normal: normalSpec, selected: selectedSpec)
    let compositionLeading = makeVerticalCompositionLeadingButton(normal: normalSpec, selected: selectedSpec)
    let compositionBoth = makeVerticalCompositionBothButton(normal: normalSpec, selected: selectedSpec)
    
    [textOnly, iconOnly, compositionLeading, compositionBoth].forEach { stack.addArrangedSubview($0) }
    return stack
  }

  private func makeVerticalTextOnlyButton(normal: AppearanceSpec, selected: AppearanceSpec) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .textOnly)
    button.axis = .vertical
    setStatefulTitle("Text Only", on: button, normal: normal, selected: selected)
    button.setAppearance(makeAppearance(from: normal), for: .normal)
    button.setAppearance(makeAppearance(from: selected), for: .selected)
    button.setAppearance(makeAppearance(from: selected), for: .highlighted)
    button.setAppearance(makeAppearance(from: normal), for: .disabled)
    button.isSelected = true
    button.heightAnchor.constraint(equalToConstant: 56).isActive = true
    button.widthAnchor.constraint(equalToConstant: 200).isActive = true
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.didTapButton("Vertical: Text Only")
    }, for: .touchUpInside)
    return button
  }

  private func makeVerticalIconOnlyButton(normal: AppearanceSpec, selected: AppearanceSpec) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .imageOnly)
    button.axis = .vertical
    setStatefulImage(UIImage(systemName: "star.fill"), on: button, normal: normal, selected: selected)
    button.accessibilityLabel = "star"
    button.setAppearance(makeAppearance(from: normal), for: .normal)
    button.setAppearance(makeAppearance(from: selected), for: .selected)
    button.setAppearance(makeAppearance(from: selected), for: .highlighted)
    button.setAppearance(makeAppearance(from: normal), for: .disabled)
    button.isSelected = true
    button.heightAnchor.constraint(equalToConstant: 84).isActive = true
    button.widthAnchor.constraint(equalToConstant: 200).isActive = true
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.didTapButton("Vertical: Icon Only")
    }, for: .touchUpInside)
    return button
  }

  private func makeVerticalCompositionLeadingButton(normal: AppearanceSpec, selected: AppearanceSpec) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .textAndImage(.leading))
    button.axis = .vertical
    setStatefulTitle("Leading", on: button, normal: normal, selected: selected)
    setStatefulImage(UIImage(systemName: "paperplane.fill"), on: button, normal: normal, selected: selected, position: .leading)
    button.setAppearance(makeAppearance(from: normal), for: .normal)
    button.setAppearance(makeAppearance(from: selected), for: .selected)
    button.setAppearance(makeAppearance(from: selected), for: .highlighted)
    button.setAppearance(makeAppearance(from: normal), for: .disabled)
    button.isSelected = true
    button.heightAnchor.constraint(equalToConstant: 96).isActive = true
    button.widthAnchor.constraint(equalToConstant: 200).isActive = true
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.didTapButton("Vertical: Composition Leading")
    }, for: .touchUpInside)
    return button
  }

  private func makeVerticalCompositionBothButton(normal: AppearanceSpec, selected: AppearanceSpec) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .textAndImage(.bothSides))
    button.axis = .vertical
    setStatefulTitle("Both", on: button, normal: normal, selected: selected)
    setStatefulImage(UIImage(systemName: "chevron.left"), on: button, normal: normal, selected: selected, position: .leading)
    setStatefulImage(UIImage(systemName: "chevron.right"), on: button, normal: normal, selected: selected, position: .trailing)
    button.setAppearance(makeAppearance(from: normal), for: .normal)
    button.setAppearance(makeAppearance(from: selected), for: .selected)
    button.setAppearance(makeAppearance(from: selected), for: .highlighted)
    button.setAppearance(makeAppearance(from: normal), for: .disabled)
    button.isSelected = true
    button.heightAnchor.constraint(equalToConstant: 96).isActive = true
    button.widthAnchor.constraint(equalToConstant: 200).isActive = true
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.didTapButton("Vertical: Composition Both")
    }, for: .touchUpInside)
    return button
  }
  
  func makeCapsuleCornerDemo() -> UIView {
    let button = FKButton()
    button.content = .init(kind: .textOnly)
    button.setTitle(.init(text: "Capsule", color: .white), for: .normal)
    
    let normalSpec = AppearanceSpec(
      foregroundColor: .white,
      backgroundColor: .systemPink,
      borderColor: .systemPink,
      borderWidth: 0,
      corner: .capsule,
      shadow: nil
    )
    
    button.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    
    button.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Capsule Corner")
    }, for: .touchUpInside)
    
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    button.widthAnchor.constraint(equalToConstant: 220).isActive = true
    return button
  }
  
  func makeNoBorderDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    
    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .tertiarySystemBackground,
      borderColor: .clear,
      borderWidth: 0,
      corner: .fixed(12),
      shadow: nil
    )

    let disabledSpec = AppearanceSpec(
      foregroundColor: .secondaryLabel,
      backgroundColor: .systemGray6,
      borderColor: .clear,
      borderWidth: 0,
      corner: .fixed(12),
      shadow: nil
    )
    
    let firstButton = FKButton()
    firstButton.content = .init(kind: .textOnly)
    firstButton.setTitle(.init(text: "No Border", color: normalSpec.foregroundColor), for: .normal)
    firstButton.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    
    firstButton.addAction(UIAction { [weak self] _ in
      self?.didTapButton("No Border")
    }, for: .touchUpInside)
    
    let disabledButton = FKButton()
    disabledButton.content = .init(kind: .textOnly)
    disabledButton.setTitle(.init(text: "Disabled", color: disabledSpec.foregroundColor), for: .normal)
    disabledButton.isEnabled = false
    disabledButton.setAppearance(makeAppearance(from: disabledSpec), for: .disabled)
    
    firstButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    disabledButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    stack.addArrangedSubview(firstButton)
    stack.addArrangedSubview(disabledButton)
    return stack
  }
  
  func makeDifferentLengthDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    
    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .tertiarySystemBackground,
      borderColor: .separator,
      borderWidth: 1,
      corner: .fixed(12),
      shadow: nil
    )
    
    func makeTextButton(title: String) -> FKButton {
      let button = FKButton()
      button.content = .init(kind: .textOnly)
      button.setTitle(.init(text: title, color: normalSpec.foregroundColor), for: .normal)
      button.setAppearance(makeAppearance(from: normalSpec), for: .normal)
      button.setAppearance(makeAppearance(from: normalSpec), for: .selected)
      button.setAppearance(makeAppearance(from: normalSpec), for: .highlighted)
      button.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
      button.heightAnchor.constraint(equalToConstant: 44).isActive = true
      button.widthAnchor.constraint(equalToConstant: view.bounds.width - DemoMetrics.inset * 2).isActive = true
      button.addAction(UIAction { [weak self] _ in
        self?.didTapButton("Different Length: \(title)")
      }, for: .touchUpInside)
      return button
    }
    
    stack.addArrangedSubview(makeTextButton(title: "Short"))
    stack.addArrangedSubview(makeTextButton(title: "Medium length"))
    stack.addArrangedSubview(makeTextButton(title: "A very very very long title"))
    
    return stack
  }

  // MARK: - Content.Kind switching (tests on-demand subview create / teardown)

  private func contentKindDescription(_ kind: FKButton.Content.Kind) -> String {
    switch kind {
    case .textOnly:
      return ".textOnly"
    case .imageOnly:
      return ".imageOnly"
    case .textAndImage(.leading):
      return ".textAndImage(.leading)"
    case .textAndImage(.trailing):
      return ".textAndImage(.trailing)"
    case .textAndImage(.bothSides):
      return ".textAndImage(.bothSides)"
    case .custom:
      return ".custom"
    }
  }

  /// 按 `kind` 配置 `FKButton` 的标题 / 图片 / 自定义视图与外观（用于动态切换 `content` 的调试入口）。
  private func configureMorphingDemoButton(
    _ button: FKButton,
    kind: FKButton.Content.Kind,
    normal: AppearanceSpec,
    selected: AppearanceSpec,
    axis: FKButton.Axis = .horizontal
  ) {
    button.axis = axis
    button.content = .init(kind: kind)

    button.setAppearance(makeAppearance(from: normal), for: .normal)
    button.setAppearance(makeAppearance(from: selected), for: .selected)
    button.setAppearance(makeAppearance(from: selected), for: .highlighted)
    button.setAppearance(makeAppearance(from: normal), for: .disabled)

    switch kind {
    case .textOnly:
      setStatefulTitle("Morph", on: button, normal: normal, selected: selected)
    case .imageOnly:
      setStatefulImage(UIImage(systemName: "sparkles"), on: button, normal: normal, selected: selected, position: nil)
      button.accessibilityLabel = "sparkles"
    case .textAndImage(let placement):
      setStatefulTitle("Morph", on: button, normal: normal, selected: selected)
      switch placement {
      case .leading:
        setStatefulImage(UIImage(systemName: "leaf.fill"), on: button, normal: normal, selected: selected, position: .leading)
      case .trailing:
        setStatefulImage(UIImage(systemName: "leaf.fill"), on: button, normal: normal, selected: selected, position: .trailing)
      case .bothSides:
        setStatefulImage(UIImage(systemName: "arrow.left"), on: button, normal: normal, selected: selected, position: .leading)
        setStatefulImage(UIImage(systemName: "arrow.right"), on: button, normal: normal, selected: selected, position: .trailing)
      }
    case .custom:
      let customView = makeDemoCustomContentView(
        title: "UIView",
        foreground: normal.foregroundColor,
        background: normal.backgroundColor,
        border: normal.borderColor
      )
      let cc = FKButton.CustomContent(view: customView, spacingToAdjacentContent: 8)
      button.setCustomContent(cc, for: .normal)
      button.setCustomContent(cc, for: .selected)
      button.setCustomContent(cc, for: .highlighted)
      button.setCustomContent(cc, for: .disabled)
    }
  }

  private func makeDemoCustomContentView(
    title: String,
    foreground: UIColor,
    background: UIColor,
    border: UIColor
  ) -> UIView {
    let label = UILabel()
    label.text = title
    label.font = .systemFont(ofSize: 14, weight: .semibold)
    label.textColor = foreground
    label.textAlignment = .center
    label.backgroundColor = background
    label.layer.cornerRadius = 8
    label.clipsToBounds = true
    label.layer.borderWidth = 1
    label.layer.borderColor = border.cgColor
    return label
  }

  private func morphingAppearanceSpecs() -> (normal: AppearanceSpec, selected: AppearanceSpec) {
    let normal = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .tertiarySystemBackground,
      borderColor: .separator,
      borderWidth: 1,
      corner: .fixed(12),
      shadow: nil
    )
    let selected = AppearanceSpec(
      foregroundColor: .systemBlue,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .none,
      shadow: nil
    )
    return (normal, selected)
  }

  /// 依次遍历 `textOnly → imageOnly → 三种 textAndImage → custom`，点击目标按钮切换。
  func makeContentKindCycleAllDemo() -> UIView {
    let (normal, selected) = morphingAppearanceSpecs()
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let status = UILabel()
    status.font = .preferredFont(forTextStyle: .caption1)
    status.textColor = .secondaryLabel
    status.textAlignment = .center
    status.numberOfLines = 0

    let kinds: [FKButton.Content.Kind] = [
      .textOnly,
      .imageOnly,
      .textAndImage(.leading),
      .textAndImage(.trailing),
      .textAndImage(.bothSides),
      .custom,
    ]

    let morph = FKButton()
    morph.isSelected = true
    var index = 0

    func applyCurrent() {
      let kind = kinds[index % kinds.count]
      configureMorphingDemoButton(morph, kind: kind, normal: normal, selected: selected)
      status.text = "content.kind：\(contentKindDescription(kind))\n（点按钮循环下一种）"
    }

    morph.addAction(UIAction { [weak self] _ in
      index = (index + 1) % kinds.count
      applyCurrent()
      self?.didTapButton("ContentKind cycle → \(self?.contentKindDescription(kinds[index % kinds.count]) ?? "")")
    }, for: .touchUpInside)

    applyCurrent()
    morph.heightAnchor.constraint(equalToConstant: 52).isActive = true
    morph.widthAnchor.constraint(equalToConstant: 240).isActive = true

    stack.addArrangedSubview(status)
    stack.addArrangedSubview(morph)
    return stack
  }

  /// 多枚系统按钮直接跳到某一种 `Content.Kind`。
  func makeContentKindPickerDemo() -> UIView {
    let (normal, selected) = morphingAppearanceSpecs()
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .center
    outer.spacing = 10
    outer.translatesAutoresizingMaskIntoConstraints = false

    let hint = UILabel()
    hint.font = .preferredFont(forTextStyle: .caption1)
    hint.textColor = .secondaryLabel
    hint.textAlignment = .center
    hint.numberOfLines = 0
    hint.text = "下方按钮设置中间 `FKButton` 的 `content.kind`（不循环）。"

    let morph = FKButton()
    morph.isSelected = true
    morph.heightAnchor.constraint(equalToConstant: 52).isActive = true
    morph.widthAnchor.constraint(equalToConstant: 260).isActive = true

    let row1 = UIStackView()
    row1.axis = .horizontal
    row1.spacing = 8
    row1.distribution = .fillEqually

    let row2 = UIStackView()
    row2.axis = .horizontal
    row2.spacing = 8
    row2.distribution = .fillEqually

    func wire(_ ui: UIButton, kind: FKButton.Content.Kind) {
      ui.addAction(UIAction { [weak self] _ in
        self?.configureMorphingDemoButton(morph, kind: kind, normal: normal, selected: selected)
        self?.didTapButton("ContentKind pick \(self?.contentKindDescription(kind) ?? "")")
      }, for: .touchUpInside)
    }

    let bText = UIButton(type: .system)
    bText.setTitle("textOnly", for: .normal)
    wire(bText, kind: .textOnly)

    let bIcon = UIButton(type: .system)
    bIcon.setTitle("imageOnly", for: .normal)
    wire(bIcon, kind: .imageOnly)

    let bLead = UIButton(type: .system)
    bLead.setTitle("+ leading", for: .normal)
    wire(bLead, kind: .textAndImage(.leading))

    let bTrail = UIButton(type: .system)
    bTrail.setTitle("+ trailing", for: .normal)
    wire(bTrail, kind: .textAndImage(.trailing))

    let bBoth = UIButton(type: .system)
    bBoth.setTitle("+ both", for: .normal)
    wire(bBoth, kind: .textAndImage(.bothSides))

    let bCustom = UIButton(type: .system)
    bCustom.setTitle("custom", for: .normal)
    wire(bCustom, kind: .custom)

    row1.addArrangedSubview(bText)
    row1.addArrangedSubview(bIcon)
    row1.addArrangedSubview(bLead)
    row2.addArrangedSubview(bTrail)
    row2.addArrangedSubview(bBoth)
    row2.addArrangedSubview(bCustom)

    configureMorphingDemoButton(morph, kind: .textOnly, normal: normal, selected: selected)

    outer.addArrangedSubview(hint)
    outer.addArrangedSubview(morph)
    outer.addArrangedSubview(row1)
    outer.addArrangedSubview(row2)
    return outer
  }

  /// 仅 `.textOnly` ↔ `.custom` 互切，用于观察「从未创建图片槽」路径。
  func makeContentKindTextCustomPingPongDemo() -> UIView {
    let (normal, selected) = morphingAppearanceSpecs()
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let status = UILabel()
    status.font = .preferredFont(forTextStyle: .caption1)
    status.textColor = .secondaryLabel
    status.textAlignment = .center

    let morph = FKButton()
    morph.isSelected = true
    morph.heightAnchor.constraint(equalToConstant: 52).isActive = true
    morph.widthAnchor.constraint(equalToConstant: 220).isActive = true

    var useText = true

    func refresh() {
      if useText {
        configureMorphingDemoButton(morph, kind: .textOnly, normal: normal, selected: selected)
        status.text = "当前：.textOnly — 点「切换」→ .custom"
      } else {
        configureMorphingDemoButton(morph, kind: .custom, normal: normal, selected: selected)
        status.text = "当前：.custom — 点「切换」→ .textOnly"
      }
    }

    let toggle = UIButton(type: .system)
    toggle.setTitle("切换 textOnly ↔ custom", for: .normal)
    toggle.addAction(UIAction { [weak self] _ in
      useText.toggle()
      refresh()
      self?.didTapButton("ContentKind text ↔ custom")
    }, for: .touchUpInside)

    refresh()
    stack.addArrangedSubview(status)
    stack.addArrangedSubview(morph)
    stack.addArrangedSubview(toggle)
    return stack
  }

  /// 仅在三种 `textAndImage` 间循环，测试不同槽位 `UIImageView` 的创建与回收。
  func makeContentKindPlacementCycleDemo() -> UIView {
    let (normal, selected) = morphingAppearanceSpecs()
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let status = UILabel()
    status.font = .preferredFont(forTextStyle: .caption1)
    status.textColor = .secondaryLabel
    status.textAlignment = .center

    let placements: [FKButton.Content.Kind] = [
      .textAndImage(.leading),
      .textAndImage(.trailing),
      .textAndImage(.bothSides),
    ]
    var idx = 0
    let morph = FKButton()
    morph.isSelected = true
    morph.heightAnchor.constraint(equalToConstant: 52).isActive = true
    morph.widthAnchor.constraint(equalToConstant: 260).isActive = true

    func apply() {
      let kind = placements[idx % placements.count]
      configureMorphingDemoButton(morph, kind: kind, normal: normal, selected: selected)
      status.text = "placement：\(contentKindDescription(kind))"
    }

    morph.addAction(UIAction { [weak self] _ in
      idx = (idx + 1) % placements.count
      apply()
      self?.didTapButton("ContentKind placement cycle")
    }, for: .touchUpInside)

    apply()
    stack.addArrangedSubview(status)
    stack.addArrangedSubview(morph)
    return stack
  }

  /// 竖直轴 + 与「Cycle all」相同的 kind 序列，覆盖 `axis` 与内容切换叠加。
  func makeContentKindVerticalCycleDemo() -> UIView {
    let (normal, selected) = morphingAppearanceSpecs()
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let status = UILabel()
    status.font = .preferredFont(forTextStyle: .caption1)
    status.textColor = .secondaryLabel
    status.textAlignment = .center
    status.numberOfLines = 0

    let kinds: [FKButton.Content.Kind] = [
      .textOnly,
      .imageOnly,
      .textAndImage(.leading),
      .custom,
    ]
    var index = 0
    let morph = FKButton()
    morph.isSelected = true
    morph.heightAnchor.constraint(equalToConstant: 96).isActive = true
    morph.widthAnchor.constraint(equalToConstant: 200).isActive = true

    func applyCurrent() {
      let kind = kinds[index % kinds.count]
      configureMorphingDemoButton(morph, kind: kind, normal: normal, selected: selected, axis: .vertical)
      status.text = "axis：vertical\n\(contentKindDescription(kind))"
    }

    morph.addAction(UIAction { [weak self] _ in
      index = (index + 1) % kinds.count
      applyCurrent()
      self?.didTapButton("ContentKind vertical cycle")
    }, for: .touchUpInside)

    applyCurrent()
    stack.addArrangedSubview(status)
    stack.addArrangedSubview(morph)
    return stack
  }

  // MARK: - Subtitle demos

  private func setStatefulSubtitle(
    _ text: String,
    on button: FKButton,
    normal: AppearanceSpec,
    selected: AppearanceSpec,
    highlighted: AppearanceSpec? = nil
  ) {
    let highlightSpec = highlighted ?? selected
    button.setSubtitle(
      .init(text: text, font: .systemFont(ofSize: 12, weight: .regular), color: normal.foregroundColor),
      for: .normal
    )
    button.setSubtitle(
      .init(text: text, font: .systemFont(ofSize: 12, weight: .regular), color: selected.foregroundColor),
      for: .selected
    )
    button.setSubtitle(
      .init(text: text, font: .systemFont(ofSize: 12, weight: .regular), color: highlightSpec.foregroundColor),
      for: .highlighted
    )
    button.setSubtitle(
      .init(text: text, font: .systemFont(ofSize: 12, weight: .regular), color: .secondaryLabel),
      for: .disabled
    )
  }

  func makeSubtitleTextOnlyDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .fixed(12),
      shadow: nil
    )

    let selectedSpec = AppearanceSpec(
      foregroundColor: .systemBlue,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .none,
      shadow: nil
    )

    let normalBtn = FKButton()
    normalBtn.content = .init(kind: .textOnly)
    setStatefulTitle("Normal", on: normalBtn, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("Subtitle", on: normalBtn, normal: normalSpec, selected: selectedSpec)
    normalBtn.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    normalBtn.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    normalBtn.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    normalBtn.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    normalBtn.heightAnchor.constraint(equalToConstant: 64).isActive = true

    let selectedBtn = FKButton()
    selectedBtn.content = .init(kind: .textOnly)
    setStatefulTitle("Selected", on: selectedBtn, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("Subtitle", on: selectedBtn, normal: normalSpec, selected: selectedSpec)
    selectedBtn.isSelected = true
    selectedBtn.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    selectedBtn.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    selectedBtn.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    selectedBtn.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    selectedBtn.heightAnchor.constraint(equalToConstant: 64).isActive = true
    selectedBtn.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Subtitle: Selected")
    }, for: .touchUpInside)

    let highlightedBtn = FKButton()
    highlightedBtn.content = .init(kind: .textOnly)
    setStatefulTitle("Press & Hold", on: highlightedBtn, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("Subtitle (highlighted)", on: highlightedBtn, normal: normalSpec, selected: selectedSpec)
    highlightedBtn.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    highlightedBtn.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    highlightedBtn.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    highlightedBtn.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    highlightedBtn.heightAnchor.constraint(equalToConstant: 64).isActive = true
    highlightedBtn.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Subtitle: Highlighted (via touch)")
    }, for: .touchUpInside)

    let disabledBtn = FKButton()
    disabledBtn.content = .init(kind: .textOnly)
    setStatefulTitle("Disabled", on: disabledBtn, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("Subtitle", on: disabledBtn, normal: normalSpec, selected: selectedSpec)
    disabledBtn.isEnabled = false
    disabledBtn.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    disabledBtn.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    disabledBtn.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    disabledBtn.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    disabledBtn.heightAnchor.constraint(equalToConstant: 64).isActive = true

    normalBtn.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Subtitle: Normal")
    }, for: .touchUpInside)

    stack.addArrangedSubview(normalBtn)
    stack.addArrangedSubview(selectedBtn)
    stack.addArrangedSubview(highlightedBtn)
    stack.addArrangedSubview(disabledBtn)
    return stack
  }

  func makeSubtitleTextAndImageDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .fixed(12),
      shadow: nil
    )

    let selectedSpec = AppearanceSpec(
      foregroundColor: .systemGreen,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .none,
      shadow: nil
    )

    let leading = FKButton()
    leading.content = .init(kind: .textAndImage(.leading))
    setStatefulTitle("Leading", on: leading, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("subtitle under title", on: leading, normal: normalSpec, selected: selectedSpec)
    setStatefulImage(UIImage(systemName: "paperplane.fill"), on: leading, normal: normalSpec, selected: selectedSpec, position: .leading)
    leading.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    leading.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    leading.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    leading.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    leading.heightAnchor.constraint(equalToConstant: 64).isActive = true
    leading.widthAnchor.constraint(equalToConstant: 260).isActive = true
    leading.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Subtitle: textAndImage (.leading)")
    }, for: .touchUpInside)

    let both = FKButton()
    both.content = .init(kind: .textAndImage(.bothSides))
    both.isSelected = true
    setStatefulTitle("Both", on: both, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("subtitle under title", on: both, normal: normalSpec, selected: selectedSpec)
    setStatefulImage(UIImage(systemName: "chevron.left"), on: both, normal: normalSpec, selected: selectedSpec, position: .leading)
    setStatefulImage(UIImage(systemName: "chevron.right"), on: both, normal: normalSpec, selected: selectedSpec, position: .trailing)
    both.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    both.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    both.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    both.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    both.heightAnchor.constraint(equalToConstant: 64).isActive = true
    both.widthAnchor.constraint(equalToConstant: 260).isActive = true
    both.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Subtitle: textAndImage (.bothSides)")
    }, for: .touchUpInside)

    stack.addArrangedSubview(leading)
    stack.addArrangedSubview(both)
    return stack
  }

  func makeSubtitleVerticalAxisDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .fixed(12),
      shadow: nil
    )

    let selectedSpec = AppearanceSpec(
      foregroundColor: .systemBlue,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .none,
      shadow: nil
    )

    let b1 = FKButton()
    b1.content = .init(kind: .textOnly)
    b1.axis = .vertical
    setStatefulTitle("Title", on: b1, normal: normalSpec, selected: selectedSpec)
    setStatefulSubtitle("Subtitle", on: b1, normal: normalSpec, selected: selectedSpec)
    b1.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    b1.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    b1.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    b1.setAppearance(makeAppearance(from: normalSpec), for: .disabled)
    b1.heightAnchor.constraint(equalToConstant: 96).isActive = true
    b1.widthAnchor.constraint(equalToConstant: 200).isActive = true
    b1.isSelected = true
    b1.addAction(UIAction { [weak self] _ in
      self?.didTapButton("Subtitle: vertical axis")
    }, for: .touchUpInside)

    stack.addArrangedSubview(b1)
    return stack
  }

  func makeSubtitleTogglePresenceDemo() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    let normalSpec = AppearanceSpec(
      foregroundColor: .label,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .fixed(12),
      shadow: nil
    )

    let selectedSpec = AppearanceSpec(
      foregroundColor: .systemBlue,
      backgroundColor: .clear,
      borderColor: .clear,
      borderWidth: 0,
      corner: .none,
      shadow: nil
    )

    let status = UILabel()
    status.font = .preferredFont(forTextStyle: .caption1)
    status.textColor = .secondaryLabel
    status.textAlignment = .center
    status.numberOfLines = 0

    let button = FKButton()
    button.content = .init(kind: .textOnly)
    button.axis = .horizontal
    setStatefulTitle("Toggle subtitle", on: button, normal: normalSpec, selected: selectedSpec)
    button.heightAnchor.constraint(equalToConstant: 64).isActive = true
    button.widthAnchor.constraint(equalToConstant: 260).isActive = true
    button.setAppearance(makeAppearance(from: normalSpec), for: .normal)
    button.setAppearance(makeAppearance(from: selectedSpec), for: .selected)
    button.setAppearance(makeAppearance(from: selectedSpec), for: .highlighted)
    button.setAppearance(makeAppearance(from: normalSpec), for: .disabled)

    var hasSubtitle = true
    func applySubtitle() {
      if hasSubtitle {
        button.setSubtitle(
          .init(text: "I am subtitle", font: .systemFont(ofSize: 12, weight: .regular), color: normalSpec.foregroundColor),
          for: .normal
        )
        button.setSubtitle(
          .init(text: "I am subtitle", font: .systemFont(ofSize: 12, weight: .regular), color: selectedSpec.foregroundColor),
          for: .selected
        )
        button.setSubtitle(
          .init(text: "I am subtitle", font: .systemFont(ofSize: 12, weight: .regular), color: selectedSpec.foregroundColor),
          for: .highlighted
        )
        button.setSubtitle(
          .init(text: "I am subtitle", font: .systemFont(ofSize: 12, weight: .regular), color: .secondaryLabel),
          for: .disabled
        )
        status.text = "subtitle: ON (tap to remove)"
      } else {
        button.setSubtitle(nil, for: .normal)
        button.setSubtitle(nil, for: .selected)
        button.setSubtitle(nil, for: .highlighted)
        button.setSubtitle(nil, for: .disabled)
        status.text = "subtitle: OFF (tap to show)"
      }
    }

    applySubtitle()
    button.addAction(UIAction { [weak self] _ in
      hasSubtitle.toggle()
      applySubtitle()
      let text = hasSubtitle ? "ON" : "OFF"
      self?.didTapButton("Subtitle: toggle \(text)")
    }, for: .touchUpInside)

    stack.addArrangedSubview(status)
    stack.addArrangedSubview(button)
    return stack
  }
}
