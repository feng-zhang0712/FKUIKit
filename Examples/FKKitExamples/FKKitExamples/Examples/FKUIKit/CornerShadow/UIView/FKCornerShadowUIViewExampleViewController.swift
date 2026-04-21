//
// FKCornerShadowUIViewExampleViewController.swift
//
// UIView-focused FKCornerShadow scenarios.
//

import UIKit
import FKUIKit

/// Demonstrates UIView corner/shadow features with copy-ready snippets.
final class FKCornerShadowUIViewExampleViewController: UIViewController {
  private let scrollView: UIScrollView
  private let contentStack: UIStackView

  private let adaptiveCard = FKCornerShadowDemoSupport.makeDemoCard(height: 96)
  private var adaptiveExpanded = false

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    (scrollView, contentStack) = FKCornerShadowDemoSupport.makeRootScrollStack()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    (scrollView, contentStack) = FKCornerShadowDemoSupport.makeRootScrollStack()
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIView Scenarios"
    view.backgroundColor = .systemGroupedBackground
    FKCornerShadowDemoSupport.pinRootScrollStack(scrollView: scrollView, stack: contentStack, in: view)

    buildCornerSection()
    buildShadowSection()
    buildComboSection()
    buildGradientSection()
    buildAutoUpdateSection()
    buildResetSection()
  }

  private func buildCornerSection() {
    let section = FKCornerShadowDemoSupport.makeSection(
      title: "Set single/multi/all corners radius",
      subtitle: "Uses UIRectCorner for single, multiple, and all-corner rounded paths."
    )

    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 8

    let singleCorner = FKCornerShadowDemoSupport.makeDemoCard()
    singleCorner.fk_applyCornerShadow(corners: [.topLeft], cornerRadius: 20, fillColor: .systemBlue.withAlphaComponent(0.18))

    let multiCorners = FKCornerShadowDemoSupport.makeDemoCard()
    multiCorners.fk_applyCornerShadow(corners: [.topLeft, .bottomRight], cornerRadius: 22, fillColor: .systemMint.withAlphaComponent(0.18))

    let allCorners = FKCornerShadowDemoSupport.makeDemoCard()
    allCorners.fk_applyCornerShadow(corners: .allCorners, cornerRadius: 18, fillColor: .systemOrange.withAlphaComponent(0.18))

    [singleCorner, multiCorners, allCorners].forEach { row.addArrangedSubview($0) }
    section.addArrangedSubview(row)
    contentStack.addArrangedSubview(section)
  }

  private func buildShadowSection() {
    let section = FKCornerShadowDemoSupport.makeSection(
      title: "Add high performance shadow with path optimization",
      subtitle: "Uses explicit shadowPath and side control to avoid expensive implicit shadow rasterization."
    )
    let card = FKCornerShadowDemoSupport.makeDemoCard()
    card.fk_applyCornerShadow(
      corners: .allCorners,
      cornerRadius: 16,
      fillColor: .systemBackground,
      shadow: FKCornerShadowShadow(
        color: .black,
        opacity: 0.18,
        offset: CGSize(width: 0, height: 8),
        blur: 16,
        spread: 2,
        sides: [.bottom, .right]
      )
    )
    section.addArrangedSubview(card)
    contentStack.addArrangedSubview(section)
  }

  private func buildComboSection() {
    let section = FKCornerShadowDemoSupport.makeSection(
      title: "Corner + shadow + border combination",
      subtitle: "A single style object keeps corner, border, and shadow paths synchronized."
    )

    let card = FKCornerShadowDemoSupport.makeDemoCard(height: 100)
    let style = FKCornerShadowStyle(
      corners: [.topLeft, .topRight, .bottomRight],
      cornerRadius: 24,
      fillColor: .systemBackground,
      border: .solid(color: .systemPurple, width: 1.2),
      shadow: FKCornerShadowShadow(
        color: .black,
        opacity: 0.16,
        offset: CGSize(width: 0, height: 6),
        blur: 14,
        spread: 0,
        sides: .all
      )
    )
    card.fk_applyCornerShadow(style)
    section.addArrangedSubview(card)
    contentStack.addArrangedSubview(section)
  }

  private func buildGradientSection() {
    let section = FKCornerShadowDemoSupport.makeSection(
      title: "Add gradient background + rounded corners",
      subtitle: "Supports gradient fill plus gradient border using the same rounded path."
    )

    let card = FKCornerShadowDemoSupport.makeDemoCard(height: 104)
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
      shadow: FKCornerShadowShadow(opacity: 0.2, offset: CGSize(width: 0, height: 8), blur: 18, spread: 2, sides: .all)
    )

    section.addArrangedSubview(card)
    contentStack.addArrangedSubview(section)
  }

  private func buildAutoUpdateSection() {
    let section = FKCornerShadowDemoSupport.makeSection(
      title: "Auto update corner on frame change",
      subtitle: "Corner and shadow paths refresh automatically when bounds change."
    )
    adaptiveCard.fk_applyCornerShadowFromGlobal { style in
      style.corners = [.topLeft, .bottomLeft, .bottomRight]
      style.cornerRadius = 28
      style.shadow = FKCornerShadowShadow(opacity: 0.16, offset: CGSize(width: 0, height: 7), blur: 14, spread: 1, sides: [.bottom])
    }

    let toggle = FKCornerShadowDemoSupport.makeActionButton(title: "Toggle Card Height") { [weak self] in
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
    let section = FKCornerShadowDemoSupport.makeSection(
      title: "Reset all styles",
      subtitle: "Use reset APIs for reusable views and dynamic state switching."
    )

    let card = FKCornerShadowDemoSupport.makeDemoCard(height: 92)
    card.fk_applyCornerShadowFromGlobal()

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKCornerShadowDemoSupport.makeActionButton(title: "Reset All") {
      card.fk_resetCornerShadow()
    })
    row.addArrangedSubview(FKCornerShadowDemoSupport.makeActionButton(title: "Reset Shadow") {
      card.fk_resetShadow()
    })
    row.addArrangedSubview(FKCornerShadowDemoSupport.makeActionButton(title: "Reapply") {
      card.fk_applyCornerShadowFromGlobal()
    })

    section.addArrangedSubview(card)
    section.addArrangedSubview(row)
    contentStack.addArrangedSubview(section)
  }
}
