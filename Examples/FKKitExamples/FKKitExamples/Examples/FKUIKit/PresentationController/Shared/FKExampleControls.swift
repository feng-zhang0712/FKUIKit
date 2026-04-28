import UIKit

/// A small set of copy-friendly UIKit controls used by examples.
enum FKExampleControls {
  static func toggle(
    title: String,
    isOn: Bool,
    onChange: @escaping (Bool) -> Void
  ) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.numberOfLines = 0

    let toggle = UISwitch()
    toggle.isOn = isOn
    toggle.addAction(UIAction { _ in onChange(toggle.isOn) }, for: .valueChanged)

    row.addArrangedSubview(label)
    row.addArrangedSubview(UIView())
    row.addArrangedSubview(toggle)
    return card(row)
  }

  static func slider(
    title: String,
    value: Float,
    range: ClosedRange<Float>,
    valueText: @escaping (Float) -> String = { String(format: "%.2f", $0) },
    onChange: @escaping (Float) -> Void
  ) -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let header = UIStackView()
    header.axis = .horizontal
    header.alignment = .firstBaseline

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.numberOfLines = 0

    let valueLabel = UILabel()
    valueLabel.text = valueText(value)
    valueLabel.font = .preferredFont(forTextStyle: .callout)
    valueLabel.textColor = .secondaryLabel

    header.addArrangedSubview(label)
    header.addArrangedSubview(UIView())
    header.addArrangedSubview(valueLabel)

    let slider = UISlider()
    slider.minimumValue = range.lowerBound
    slider.maximumValue = range.upperBound
    slider.value = value
    slider.addAction(UIAction { _ in
      valueLabel.text = valueText(slider.value)
      onChange(slider.value)
    }, for: .valueChanged)

    stack.addArrangedSubview(header)
    stack.addArrangedSubview(slider)
    return card(stack)
  }

  static func segmented(
    title: String,
    items: [String],
    selectedIndex: Int,
    onChange: @escaping (Int) -> Void
  ) -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.numberOfLines = 0

    let control = UISegmentedControl(items: items)
    control.selectedSegmentIndex = selectedIndex
    control.addAction(UIAction { _ in onChange(control.selectedSegmentIndex) }, for: .valueChanged)

    stack.addArrangedSubview(label)
    stack.addArrangedSubview(control)
    return card(stack)
  }

  static func infoLabel(text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .callout)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  private static func card(_ content: UIView) -> UIView {
    let card = UIView()
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12

    content.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(content)
    NSLayoutConstraint.activate([
      content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
      content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
      content.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
      content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
    ])
    return card
  }
}

