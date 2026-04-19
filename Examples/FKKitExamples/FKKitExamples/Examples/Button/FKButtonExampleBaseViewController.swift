//
//  FKButtonExampleBaseViewController.swift
//  FKKitExamples
//
//  Shared scroll layout and appearance helpers for split FKButton demos.
//

import UIKit
import FKUIKit

class FKButtonExampleBaseViewController: UIViewController {

  enum Metrics {
    static let inset: CGFloat = 16
    static let spacing: CGFloat = 14
    static let buttonHeight: CGFloat = 44
  }

  private(set) lazy var rootStackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = Metrics.spacing
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()

  func recordDemoTap(_ name: String) {
    title = "FKButton · \(name)"
  }

  func addDemoSection(title: String, content: UIView) {
    rootStackView.addArrangedSubview(sectionTitleLabel(title))
    rootStackView.addArrangedSubview(content)
  }

  /// Pins `view` to the container’s leading/trailing so multiline labels wrap to the scroll view width.
  func fullWidthLayoutWrapping(_ view: UIView) -> UIView {
    let box = UIView()
    box.translatesAutoresizingMaskIntoConstraints = false
    view.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      view.topAnchor.constraint(equalTo: box.topAnchor),
      view.bottomAnchor.constraint(equalTo: box.bottomAnchor),
    ])
    return box
  }

  /// Centers a subview in a full-width row so fixed-width `FKButton`s stay centered when the outer stack is `.fill`.
  func horizontallyCentered(_ view: UIView) -> UIView {
    let row = UIView()
    row.translatesAutoresizingMaskIntoConstraints = false
    view.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(view)
    NSLayoutConstraint.activate([
      view.centerXAnchor.constraint(equalTo: row.centerXAnchor),
      view.topAnchor.constraint(equalTo: row.topAnchor),
      view.bottomAnchor.constraint(equalTo: row.bottomAnchor),
    ])
    return row
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
    ])
    scrollView.addSubview(rootStackView)
    let inset = Metrics.inset
    let contentGuide = scrollView.contentLayoutGuide
    NSLayoutConstraint.activate([
      rootStackView.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: inset),
      rootStackView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: inset),
      rootStackView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -inset),
      rootStackView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
      rootStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * inset),
    ])
  }

  func addTap(_ button: FKButton, name: String) {
    button.addAction(UIAction { [weak self] _ in
      self?.recordDemoTap(name)
    }, for: .touchUpInside)
  }

  func addTapToggleSelected(_ button: FKButton, name: String) {
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.recordDemoTap(name)
    }, for: .touchUpInside)
  }

  func sectionTitleLabel(_ text: String) -> UIView {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.textAlignment = .center
    label.textColor = .label
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
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
      case .selected: return selectedForegroundColor
      case .highlighted: return highlightedForegroundColor
      case .disabled: return disabledForegroundColor
      default: return normalForegroundColor
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
