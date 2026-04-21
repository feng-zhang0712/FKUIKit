//
// FKCarouselImageCell.swift
//

import UIKit

/// Reusable carousel cell used for local and remote image rendering.
///
/// This cell keeps image loading cancellation inside reuse lifecycle to prevent
/// wrong-image flashes during fast scrolling.
final class FKCarouselImageCell: UICollectionViewCell {
  /// Reuse identifier for `UICollectionView` registration/dequeue.
  static let reuseIdentifier = "FKCarouselImageCell"

  /// Backing image view pinned to `contentView`.
  private let imageView = UIImageView()
  /// Token for the current remote loading request.
  private var loadingToken: UUID?

  /// Creates cell programmatically.
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  /// Creates cell from Interface Builder.
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  /// Resets transient state before reuse.
  override func prepareForReuse() {
    super.prepareForReuse()
    // Cancel stale network work before cell is reused.
    FKCarouselImageLoader.shared.cancel(loadingToken)
    loadingToken = nil
    imageView.image = nil
  }

  /// Configures image content and loading behavior.
  ///
  /// - Parameters:
  ///   - item: Carousel data item for the current index.
  ///   - placeholder: Placeholder image shown before remote loading completes.
  ///   - failureImage: Fallback image shown when loading fails.
  ///   - contentMode: Image view content mode for rendering.
  func configure(
    with item: FKCarouselItem,
    placeholder: UIImage?,
    failureImage: UIImage?,
    contentMode: UIView.ContentMode
  ) {
    imageView.contentMode = contentMode
    switch item {
    case .image(let image):
      imageView.image = image
    case .url(let url):
      imageView.image = placeholder
      loadingToken = FKCarouselImageLoader.shared.loadImage(url: url) { [weak self] image in
        self?.imageView.image = image ?? failureImage ?? placeholder
      }
    case .customView, .customViewProvider:
      imageView.image = placeholder
    }
  }

  /// Builds static view hierarchy for image rendering.
  private func setupUI() {
    // Clip to avoid drawing outside bounds and keep paging visuals clean.
    contentView.clipsToBounds = true
    imageView.clipsToBounds = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
