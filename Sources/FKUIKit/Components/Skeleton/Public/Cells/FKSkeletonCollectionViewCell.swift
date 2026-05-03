import UIKit

/// Collection cell dedicated to skeleton placeholders (register with its own reuse identifier).
open class FKSkeletonCollectionViewCell: UICollectionViewCell {

  public let skeletonContainer = FKSkeletonContainerView()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    skeletonContainer.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(skeletonContainer)
    NSLayoutConstraint.activate([
      skeletonContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
      skeletonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      skeletonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      skeletonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  public func resetSkeletonContent() {
    skeletonContainer.removeAllSkeletonSubviews()
  }
}
