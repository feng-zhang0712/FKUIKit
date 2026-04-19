//
// FKSkeletonTableViewCell.swift
//

import UIKit

/// A dedicated table cell that hosts skeleton layouts. Use a **separate** reuse identifier from real
/// content cells so loading rows never share constraints with your data-driven UI.
open class FKSkeletonTableViewCell: UITableViewCell {

  /// Root container for `FKSkeletonPresets` or custom `FKSkeletonView` hierarchies.
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

  /// Clears skeleton blocks before attaching a new preset (safe for reuse).
  public func resetSkeletonContent() {
    skeletonContainer.removeAllSkeletonSubviews()
  }
}
