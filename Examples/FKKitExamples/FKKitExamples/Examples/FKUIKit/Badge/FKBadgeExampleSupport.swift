import UIKit
import FKUIKit

// MARK: - Layout helpers

enum FKBadgeExampleSupport {

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    let contentStack = UIStackView()
    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.spacing = 20
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)
    return (scrollView, contentStack)
  }

  static func pinScrollView(
    _ scrollView: UIScrollView,
    contentStack: UIStackView,
    in view: UIView
  ) {
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  static func addGlobalBadgeBarButtons(to vc: UIViewController) {
    vc.navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        title: "Hide all",
        image: nil,
        primaryAction: UIAction { _ in FKBadge.hideAllBadges(animated: true) },
        menu: nil
      ),
      UIBarButtonItem(
        title: "Restore all",
        image: nil,
        primaryAction: UIAction { _ in FKBadge.restoreAllBadges(animated: true) },
        menu: nil
      ),
    ]
  }

  static func sectionContainer(title: String) -> UIStackView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 8
    let h = UILabel()
    h.font = .preferredFont(forTextStyle: .subheadline)
    h.textColor = .secondaryLabel
    h.text = title
    outer.addArrangedSubview(h)
    return outer
  }

  static func leadingAlignedChipContainer(_ chip: UIView) -> UIView {
    let wrap = UIView()
    wrap.translatesAutoresizingMaskIntoConstraints = false
    wrap.addSubview(chip)
    NSLayoutConstraint.activate([
      chip.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      chip.topAnchor.constraint(equalTo: wrap.topAnchor),
      chip.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
    ])
    return wrap
  }

  static func makeChipTarget() -> UIView {
    let v = UIView()
    v.backgroundColor = .tertiarySystemFill
    v.layer.cornerRadius = 8
    v.translatesAutoresizingMaskIntoConstraints = false
    v.widthAnchor.constraint(equalToConstant: 56).isActive = true
    v.heightAnchor.constraint(equalToConstant: 56).isActive = true
    return v
  }

  static func staticNumberChip(_ n: Int) -> UIView {
    let v = makeChipTarget()
    v.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -3, vertical: 3))
    v.fk_badge.showCount(n)
    return v
  }

  static func textDemoChip(_ text: String) -> UIView {
    let wrap = UIView()
    wrap.backgroundColor = .secondarySystemFill
    wrap.layer.cornerRadius = 8
    wrap.translatesAutoresizingMaskIntoConstraints = false
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 13, weight: .medium)
    l.textAlignment = .center
    l.translatesAutoresizingMaskIntoConstraints = false
    wrap.addSubview(l)
    NSLayoutConstraint.activate([
      wrap.heightAnchor.constraint(equalToConstant: 44),
      l.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
      l.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 8),
      l.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -8),
    ])
    wrap.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -2, vertical: 2))
    wrap.fk_badge.showText(text)
    return wrap
  }

  static func styleCornerHost(_ v: UIView) {
    v.backgroundColor = .tertiarySystemFill
    v.layer.cornerRadius = 8
    v.translatesAutoresizingMaskIntoConstraints = false
  }

  static func applyAnchor(_ a: FKBadgeAnchor, to target: UIView) {
    let inset = CGFloat(4)
    switch a {
    case .topLeading:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: inset, vertical: inset))
    case .topTrailing:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: -inset, vertical: inset))
    case .bottomLeading:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: inset, vertical: -inset))
    case .bottomTrailing:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: -inset, vertical: -inset))
    case .center:
      target.fk_badge.setAnchor(a, offset: .zero)
    }
    target.fk_badge.showCount(7)
  }

  static func makeActionButton(_ title: String, handler: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.backgroundColor = .secondarySystemFill
    b.layer.cornerRadius = 8
    b.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    return b
  }
}

// MARK: - Shared scroll shell

@MainActor
class FKBadgeExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKBadgeExampleSupport.makeRootScrollStack()
    scrollView = pair.0
    contentStack = pair.1
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    let pair = FKBadgeExampleSupport.makeRootScrollStack()
    scrollView = pair.0
    contentStack = pair.1
    super.init(coder: coder)
  }

  func installScrollRootChrome() {
    view.backgroundColor = .systemGroupedBackground
    FKBadgeExampleSupport.addGlobalBadgeBarButtons(to: self)
    FKBadgeExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)
  }
}
