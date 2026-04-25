import UIKit

final class FKExampleHeaderView: UIView {
  let titleLabel = UILabel()
  let subtitleLabel = UILabel()
  let notesLabel = UILabel()

  private let container = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    container.axis = .vertical
    container.spacing = 8
    container.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0

    subtitleLabel.font = .preferredFont(forTextStyle: .body)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    notesLabel.font = .preferredFont(forTextStyle: .callout)
    notesLabel.textColor = .secondaryLabel
    notesLabel.numberOfLines = 0

    let noteCard = UIView()
    noteCard.backgroundColor = .secondarySystemGroupedBackground
    noteCard.layer.cornerRadius = 12
    noteCard.translatesAutoresizingMaskIntoConstraints = false

    notesLabel.translatesAutoresizingMaskIntoConstraints = false
    noteCard.addSubview(notesLabel)

    NSLayoutConstraint.activate([
      notesLabel.leadingAnchor.constraint(equalTo: noteCard.leadingAnchor, constant: 12),
      notesLabel.trailingAnchor.constraint(equalTo: noteCard.trailingAnchor, constant: -12),
      notesLabel.topAnchor.constraint(equalTo: noteCard.topAnchor, constant: 10),
      notesLabel.bottomAnchor.constraint(equalTo: noteCard.bottomAnchor, constant: -10),
    ])

    container.addArrangedSubview(titleLabel)
    container.addArrangedSubview(subtitleLabel)
    container.addArrangedSubview(noteCard)

    addSubview(container)
    NSLayoutConstraint.activate([
      container.leadingAnchor.constraint(equalTo: leadingAnchor),
      container.trailingAnchor.constraint(equalTo: trailingAnchor),
      container.topAnchor.constraint(equalTo: topAnchor),
      container.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}

