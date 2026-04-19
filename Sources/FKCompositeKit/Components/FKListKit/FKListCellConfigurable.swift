//
// FKListCellConfigurable.swift
// FKCompositeKit — FKListKit
//
// Lightweight cell contract for list screens using ``FKListPlugin`` composition.
//

import UIKit

/// Binds a reusable ``UITableViewCell`` subtype to a stable view-model type.
///
/// Keep ``configure(with:)`` free of networking and heavy work; it runs on the main actor during scrolling.
@MainActor
public protocol FKListCellConfigurable: UITableViewCell {
  associatedtype Item
  func configure(with item: Item)
}
