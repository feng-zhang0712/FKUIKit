import FKUIKit
import UIKit

final class FKEmptyStateDarkModeExampleViewController: UIViewController {
  private let container = UIView()
  private let themeToggle = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark + Tokens"
    view.backgroundColor = .systemBackground
    buildUI()
    applyTheme()
  }

  private func buildUI() {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.alignment = .center
    row.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.text = "Force dark mode"
    row.addArrangedSubview(label)
    row.addArrangedSubview(themeToggle)

    themeToggle.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(row)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      row.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      container.topAnchor.constraint(equalTo: row.bottomAnchor, constant: 10),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func themeChanged() {
    applyTheme()
  }

  private func applyTheme() {
    overrideUserInterfaceStyle = themeToggle.isOn ? .dark : .light
    var model = FKEmptyStateExampleFactory.makeBasicModel()
    model.title = "Token-driven appearance"
    model.description = "Override colors per scene to match your design system."
    model.titleColor = themeToggle.isOn ? .white : .black
    model.descriptionColor = themeToggle.isOn ? .lightGray : .darkGray
    model.backgroundColor = themeToggle.isOn ? UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1) : .systemBackground
    model.buttonStyle.backgroundColor = themeToggle.isOn ? .systemTeal : .systemBlue
    model.gradientColors = themeToggle.isOn ? [UIColor.black, UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1)] : []
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.fk_presentMessageAlert(title: "Token Action", message: "Primary action works in both light and dark themes.")
    }
  }
}
