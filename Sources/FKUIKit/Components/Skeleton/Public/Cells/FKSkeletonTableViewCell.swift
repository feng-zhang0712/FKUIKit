import UIKit

/// Table cell whose sole role is to host ``FKSkeletonContainerView`` placeholders during loading.
open class FKSkeletonTableViewCell: UITableViewCell {

  public let skeletonContainer = FKSkeletonContainerView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    skeletonContainer.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(skeletonContainer)
    NSLayoutConstraint.activate([
      skeletonContainer.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
      skeletonContainer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
      skeletonContainer.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
      skeletonContainer.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
    ])
  }

  /// Clears registered skeleton blocks before applying a new layout (call from `prepareForReuse`).
  public func resetSkeletonContent() {
    skeletonContainer.removeAllSkeletonSubviews()
  }
}
