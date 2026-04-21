//
// FKCarouselCustomViewCell.swift
//

import UIKit

/// Reusable carousel cell hosting arbitrary custom views.
///
/// The cell supports both direct view instances and per-cell provider-generated views.
final class FKCarouselCustomViewCell: UICollectionViewCell {
  /// Reuse identifier for `UICollectionView` registration/dequeue.
  static let reuseIdentifier = "FKCarouselCustomViewCell"

  /// Currently hosted custom view reference.
  private weak var hostedView: UIView?

  /// Removes hosted content before cell reuse.
  override func prepareForReuse() {
    super.prepareForReuse()
    hostedView?.removeFromSuperview()
    hostedView = nil
  }

  /// Configures and embeds custom content view.
  ///
  /// - Parameter item: Carousel item expected to be `.customView` or `.customViewProvider`.
  func configure(with item: FKCarouselItem) {
    hostedView?.removeFromSuperview()
    let view: UIView
    switch item {
    case .customView(let source):
      if source.superview == nil {
        view = source
      } else {
        // Fall back to snapshot to avoid moving a live source view between reused cells.
        view = source.snapshotView(afterScreenUpdates: true) ?? UIView()
      }
    case .customViewProvider(let provider):
      view = provider()
    default:
      return
    }

    view.removeFromSuperview()
    view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: contentView.topAnchor),
      view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    hostedView = view
  }
}
