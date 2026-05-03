import UIKit

/// Small layout helpers shared by ProgressBar examples (keeps scenario files readable).
enum FKProgressBarExampleLayoutHelpers {

  /// Section title styled like grouped settings headers.
  static func makeSectionLabel(_ text: String) -> UILabel {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = text
    l.font = .preferredFont(forTextStyle: .headline)
    l.textColor = .label
    l.numberOfLines = 0
    return l
  }

  /// Caption under a section (goals / expectations for QA and integrators).
  static func makeCaptionLabel(_ text: String) -> UILabel {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = text
    l.font = .preferredFont(forTextStyle: .footnote)
    l.textColor = .secondaryLabel
    l.numberOfLines = 0
    return l
  }

  /// Horizontal row: title + flexible control (switch, stepper container, etc.).
  static func makeLabeledRow(title: String, control: UIView) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    control.setContentHuggingPriority(.defaultLow, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [titleLabel, control])
    row.translatesAutoresizingMaskIntoConstraints = false
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    row.distribution = .fill
    return row
  }

  /// Card container with standard padding for scroll stacks.
  static func makeCardStack(arrangedSubviews: [UIView]) -> UIStackView {
    let inner = UIStackView(arrangedSubviews: arrangedSubviews)
    inner.translatesAutoresizingMaskIntoConstraints = false
    inner.axis = .vertical
    inner.spacing = 10
    inner.isLayoutMarginsRelativeArrangement = true
    inner.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    let card = UIStackView(arrangedSubviews: [inner])
    card.translatesAutoresizingMaskIntoConstraints = false
    card.axis = .vertical
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true
    return card
  }
}
