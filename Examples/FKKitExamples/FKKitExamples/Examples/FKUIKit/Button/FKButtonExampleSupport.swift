import UIKit
import FKUIKit

// MARK: - Shared layout & demo models

/// Static helpers for FKKitExamples button demos (mirrors the layering used by `FKBadgeExampleSupport`).
enum FKButtonExampleSupport {

  enum Metrics {
    static let inset: CGFloat = 16
    static let spacing: CGFloat = 14
    static let buttonHeight: CGFloat = 44
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

  static func makeStatefulAppearance(
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

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    let contentStack = UIStackView()
    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.spacing = Metrics.spacing
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)
    return (scrollView, contentStack)
  }

  static func pinScrollView(_ scrollView: UIScrollView, contentStack: UIStackView, in view: UIView) {
    view.addSubview(scrollView)
    let guide = view.safeAreaLayoutGuide
    let inset = Metrics.inset
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
    ])
    let contentGuide = scrollView.contentLayoutGuide
    NSLayoutConstraint.activate([
      contentStack.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: inset),
      contentStack.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: inset),
      contentStack.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -inset),
      contentStack.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * inset),
    ])
  }

  static func sectionTitleLabel(_ text: String) -> UIView {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.textAlignment = .center
    label.textColor = .label
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    return label
  }

  static func captionLabel(_ text: String) -> UIView {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.textAlignment = .natural
    label.lineBreakMode = .byWordWrapping
    return label
  }

  static func fullWidthLayoutWrapping(_ view: UIView) -> UIView {
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

  static func horizontallyCentered(_ view: UIView) -> UIView {
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
}

// MARK: - Scroll shell

@MainActor
open class FKButtonExampleScrollViewController: UIViewController {

  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKButtonExampleSupport.makeRootScrollStack()
    scrollView = pair.0
    contentStack = pair.1
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required public init?(coder: NSCoder) {
    nil
  }

  /// Subclasses override with topic-specific copy, or `nil` to hide the intro banner.
  open var pageIntroduction: String? {
    "These pages contain FKButton examples. Tap buttons to see state changes and update the navigation title."
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    FKButtonExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)
    if let intro = pageIntroduction {
      contentStack.addArrangedSubview(
        FKButtonExampleSupport.fullWidthLayoutWrapping(FKButtonExampleSupport.captionLabel(intro))
      )
    }
  }

  func recordExampleTap(_ name: String) {
    title = "FKButton · \(name)"
  }

  func addExampleSection(title: String, content: UIView) {
    contentStack.addArrangedSubview(FKButtonExampleSupport.sectionTitleLabel(title))
    contentStack.addArrangedSubview(content)
  }

  func addExampleCategory(title: String, description: String? = nil) {
    let categoryTitle = UILabel()
    categoryTitle.text = title
    categoryTitle.font = .preferredFont(forTextStyle: .title3)
    categoryTitle.textColor = .label
    categoryTitle.numberOfLines = 0
    categoryTitle.textAlignment = .left
    contentStack.addArrangedSubview(FKButtonExampleSupport.fullWidthLayoutWrapping(categoryTitle))

    if let description, !description.isEmpty {
      contentStack.addArrangedSubview(FKButtonExampleSupport.fullWidthLayoutWrapping(FKButtonExampleSupport.captionLabel(description)))
    }
  }

  func captionLabel(_ text: String) -> UIView {
    FKButtonExampleSupport.captionLabel(text)
  }

  func fullWidthLayoutWrapping(_ view: UIView) -> UIView {
    FKButtonExampleSupport.fullWidthLayoutWrapping(view)
  }

  func horizontallyCentered(_ view: UIView) -> UIView {
    FKButtonExampleSupport.horizontallyCentered(view)
  }

  func makeStatefulAppearance(
    normal: FKButtonExampleSupport.ButtonVisualSpec,
    selected: FKButtonExampleSupport.ButtonVisualSpec,
    highlighted: FKButtonExampleSupport.ButtonVisualSpec,
    disabled: FKButtonExampleSupport.ButtonVisualSpec,
    corner: FKButton.Corner = .fixed(12),
    borderWidth: CGFloat = 1
  ) -> FKButtonExampleSupport.StatefulAppearances {
    FKButtonExampleSupport.makeStatefulAppearance(
      normal: normal,
      selected: selected,
      highlighted: highlighted,
      disabled: disabled,
      corner: corner,
      borderWidth: borderWidth
    )
  }

  func addTap(_ button: FKButton, name: String) {
    button.addAction(UIAction { [weak self] _ in
      self?.recordExampleTap(name)
    }, for: .touchUpInside)
  }

  func addTapToggleSelected(_ button: FKButton, name: String) {
    button.addAction(UIAction { [weak self] _ in
      button.isSelected.toggle()
      self?.recordExampleTap(name)
    }, for: .touchUpInside)
  }
}
