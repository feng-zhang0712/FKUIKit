import UIKit
import FKUIKit

final class FKCornerShadowExampleBasicsViewController: UIViewController {
  private let scrollView: UIScrollView
  private let contentStack: UIStackView

  private let adaptiveCard = FKCornerShadowExampleSupport.makeDemoCard(height: 96)
  private var adaptiveExpanded = false

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    (scrollView, contentStack) = FKCornerShadowExampleSupport.makeRootScrollStack()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    (scrollView, contentStack) = FKCornerShadowExampleSupport.makeRootScrollStack()
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    FKCornerShadowExampleSupport.pinRootScrollStack(scrollView: scrollView, stack: contentStack, in: view)

    buildCornerSection()
    buildShadowSection()
    buildComboSection()
    buildGradientSection()
    buildAutoUpdateSection()
    buildResetSection()
  }

  private func buildCornerSection() {
    let section = FKCornerShadowExampleSupport.makeSection(
      title: "Corner radius",
      subtitle: "Single, multiple, or all corners via UIRectCorner."
    )

    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 8

    let singleCorner = FKCornerShadowExampleSupport.makeDemoCard()
    singleCorner.fk_applyCornerShadow(corners: [.topLeft], cornerRadius: 20, fillColor: .systemBlue.withAlphaComponent(0.18))

    let multiCorners = FKCornerShadowExampleSupport.makeDemoCard()
    multiCorners.fk_applyCornerShadow(corners: [.topLeft, .bottomRight], cornerRadius: 22, fillColor: .systemMint.withAlphaComponent(0.18))

    let allCorners = FKCornerShadowExampleSupport.makeDemoCard()
    allCorners.fk_applyCornerShadow(corners: .allCorners, cornerRadius: 18, fillColor: .systemOrange.withAlphaComponent(0.18))

    [singleCorner, multiCorners, allCorners].forEach { row.addArrangedSubview($0) }
    section.addArrangedSubview(row)
    contentStack.addArrangedSubview(section)
  }

  private func buildShadowSection() {
    let section = FKCornerShadowExampleSupport.makeSection(
      title: "Shadow path",
      subtitle: "Explicit shadowPath; bottom + right edges only."
    )
    let card = FKCornerShadowExampleSupport.makeDemoCard()
    card.fk_applyCornerShadow(
      corners: .allCorners,
      cornerRadius: 16,
      fillColor: .systemBackground,
      shadow: FKCornerShadowElevation(
        color: .black,
        opacity: 0.18,
        offset: CGSize(width: 0, height: 8),
        blur: 16,
        spread: 2,
        edges: [.bottom, .right]
      )
    )
    section.addArrangedSubview(card)
    contentStack.addArrangedSubview(section)
  }

  private func buildComboSection() {
    let section = FKCornerShadowExampleSupport.makeSection(
      title: "Corner + border + shadow",
      subtitle: "One FKCornerShadowStyle keeps geometry aligned."
    )

    let card = FKCornerShadowExampleSupport.makeDemoCard(height: 100)
    let style = FKCornerShadowStyle(
      corners: [.topLeft, .topRight, .bottomRight],
      cornerRadius: 24,
      fillColor: .systemBackground,
      border: .solid(color: .systemPurple, width: 1.2),
      shadow: FKCornerShadowElevation(
        color: .black,
        opacity: 0.16,
        offset: CGSize(width: 0, height: 6),
        blur: 14,
        spread: 0,
        edges: .all
      )
    )
    card.fk_applyCornerShadow(style)
    section.addArrangedSubview(card)
    contentStack.addArrangedSubview(section)
  }

  private func buildGradientSection() {
    let section = FKCornerShadowExampleSupport.makeSection(
      title: "Gradient fill & border",
      subtitle: "Same rounded path for fill gradient and stroke gradient."
    )

    let card = FKCornerShadowExampleSupport.makeDemoCard(height: 104)
    let fillGradient = FKCornerShadowGradient(
      colors: [.systemPink, .systemIndigo],
      startPoint: CGPoint(x: 0, y: 0),
      endPoint: CGPoint(x: 1, y: 1)
    )
    let borderGradient = FKCornerShadowGradient(
      colors: [.white.withAlphaComponent(0.95), .white.withAlphaComponent(0.25)],
      startPoint: CGPoint(x: 0, y: 0.5),
      endPoint: CGPoint(x: 1, y: 0.5)
    )
    card.fk_applyCornerShadow(
      corners: .allCorners,
      cornerRadius: 20,
      fillGradient: fillGradient,
      border: .gradient(gradient: borderGradient, width: 1.5),
      shadow: FKCornerShadowElevation(opacity: 0.2, offset: CGSize(width: 0, height: 8), blur: 18, spread: 2, edges: .all)
    )

    section.addArrangedSubview(card)
    contentStack.addArrangedSubview(section)
  }

  private func buildAutoUpdateSection() {
    let section = FKCornerShadowExampleSupport.makeSection(
      title: "Bounds changes",
      subtitle: "Paths refresh when layout updates bounds."
    )
    adaptiveCard.fk_applyCornerShadowFromDefaults { style in
      style.corners = [.topLeft, .bottomLeft, .bottomRight]
      style.cornerRadius = 28
      style.shadow = FKCornerShadowElevation(opacity: 0.16, offset: CGSize(width: 0, height: 7), blur: 14, spread: 1, edges: [.bottom])
    }

    let toggle = FKCornerShadowExampleSupport.makeActionButton(title: "Toggle Card Height") { [weak self] in
      guard let self else { return }
      self.adaptiveExpanded.toggle()
      let newHeight: CGFloat = self.adaptiveExpanded ? 172 : 96
      if let constraint = self.adaptiveCard.constraints.first(where: { $0.firstAttribute == .height }) {
        constraint.constant = newHeight
      }
      UIView.animate(withDuration: 0.25) {
        self.view.layoutIfNeeded()
      }
    }

    section.addArrangedSubview(adaptiveCard)
    section.addArrangedSubview(toggle)
    contentStack.addArrangedSubview(section)
  }

  private func buildResetSection() {
    let section = FKCornerShadowExampleSupport.makeSection(
      title: "Reset",
      subtitle: "Full or partial clears for reusable hosts."
    )

    let card = FKCornerShadowExampleSupport.makeDemoCard(height: 92)
    card.fk_applyCornerShadowFromDefaults()

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKCornerShadowExampleSupport.makeActionButton(title: "Reset All") {
      card.fk_resetCornerShadow()
    })
    row.addArrangedSubview(FKCornerShadowExampleSupport.makeActionButton(title: "Reset Shadow") {
      card.fk_resetShadow()
    })
    row.addArrangedSubview(FKCornerShadowExampleSupport.makeActionButton(title: "Reapply") {
      card.fk_applyCornerShadowFromDefaults()
    })

    section.addArrangedSubview(card)
    section.addArrangedSubview(row)
    contentStack.addArrangedSubview(section)
  }
}
