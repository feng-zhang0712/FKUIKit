//
// FKCornerShadowControlsExampleViewController.swift
//
// UIButton, UILabel, and UIImageView FKCornerShadow examples.
//

import UIKit
import FKUIKit

/// Demonstrates FKCornerShadow on common UIKit controls.
final class FKCornerShadowControlsExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIKit Controls"
    view.backgroundColor = .systemGroupedBackground
    buildLayout()
  }

  private func buildLayout() {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    let button = UIButton(type: .system)
    button.setTitle("Pay Now", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .systemBlue
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 52).isActive = true
    // One-line corner + shadow application.
    button.fk_applyCornerShadow(
      corners: .allCorners,
      cornerRadius: 14,
      border: .solid(color: .white.withAlphaComponent(0.7), width: 1),
      shadow: FKCornerShadowShadow(color: .black, opacity: 0.18, offset: CGSize(width: 0, height: 6), blur: 12, spread: 1, sides: .all)
    )

    let label = UILabel()
    label.textAlignment = .center
    label.numberOfLines = 0
    label.text = "UILabel styled by FKCornerShadow"
    label.backgroundColor = .systemYellow.withAlphaComponent(0.25)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.heightAnchor.constraint(equalToConstant: 70).isActive = true
    label.fk_applyCornerShadowFromGlobal { style in
      style.corners = [.topLeft, .bottomLeft, .bottomRight]
      style.cornerRadius = 18
      style.shadow = FKCornerShadowShadow(opacity: 0.14, offset: CGSize(width: 0, height: 4), blur: 10, spread: 0, sides: [.bottom])
    }

    let imageView = UIImageView(image: UIImage(systemName: "photo"))
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .systemPurple
    imageView.backgroundColor = .systemPurple.withAlphaComponent(0.15)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.heightAnchor.constraint(equalToConstant: 110).isActive = true
    imageView.fk_applyCornerShadow(
      corners: [.topLeft, .topRight],
      cornerRadius: 20,
      fillColor: .systemPurple.withAlphaComponent(0.08),
      shadow: FKCornerShadowShadow(color: .black, opacity: 0.12, offset: CGSize(width: 0, height: 5), blur: 10, spread: 0, sides: .all)
    )

    [button, label, imageView].forEach { stack.addArrangedSubview($0) }

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }
}
