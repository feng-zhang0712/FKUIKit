import UIKit

/// Shared collection tile used by skeleton grid demos (loaded state).
final class FKSkeletonExamplePhotoTileCell: UICollectionViewCell {
  let imageView = UIImageView()
  let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 10
    imageView.backgroundColor = .secondarySystemFill

    titleLabel.font = .preferredFont(forTextStyle: .caption1)

    let stack = UIStackView(arrangedSubviews: [imageView, titleLabel])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
      imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
