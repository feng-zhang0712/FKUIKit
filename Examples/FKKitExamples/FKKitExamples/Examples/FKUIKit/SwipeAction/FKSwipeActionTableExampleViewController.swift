//
// FKSwipeActionTableExampleViewController.swift
//
// UITableView demo for FKSwipeAction right-swipe multi-button scenarios.
//

import FKUIKit
import UIKit

/// Demonstrates right swipe multi-buttons on `UITableViewCell`.
///
/// Covered scenarios:
/// - Multiple buttons (text / image / image+text)
/// - Fixed width and adaptive width
/// - Per-cell enable/disable
/// - Button callbacks (delete/edit/pin/favorite)
/// - Dangerous delete confirmation
/// - Auto close on scroll
/// - Global swipe style configuration
final class FKSwipeActionTableExampleViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var items: [String] = (1...30).map { "Mail Item \($0)" }
  private var disabledIndices = Set<Int>([2, 7, 12])
  private var favoriteIndices = Set<Int>()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table Swipe (Right)"
    view.backgroundColor = .systemBackground

    configureGlobalSwipeStyle()
    setupTableView()
    setupNavigationItems()
  }

  // MARK: - Setup

  private func configureGlobalSwipeStyle() {
    // Apply one global baseline style for all swipe actions in this demo.
    FKSwipeAction.defaultConfiguration = FKSwipeActionConfiguration(
      behavior: FKSwipeActionBehaviorConfiguration(
        triggerMode: .fullWidth,
        allowsOnlyOneOpenCell: true,
        closesWhenTapMask: true,
        closesOnScroll: true,
        allowsElasticOverscroll: true,
        openThresholdRatio: 0.3,
        animationDuration: 0.26
      ),
      appearance: FKSwipeActionAppearance(
        actionAreaBackgroundColor: UIColor.systemGray6,
        maskColor: UIColor.black.withAlphaComponent(0.04),
        itemSpacing: 8,
        actionInsets: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
      )
    )
  }

  private func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.dataSource = self
    tableView.delegate = self
    tableView.rowHeight = 62
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func setupNavigationItems() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Reset",
      style: .plain,
      target: self,
      action: #selector(resetData)
    )
  }

  // MARK: - Actions

  @objc private func resetData() {
    items = (1...30).map { "Mail Item \($0)" }
    favoriteIndices.removeAll()
    disabledIndices = Set<Int>([2, 7, 12])
    tableView.reloadData()
    tableView.fk_closeAllSwipeActions(animated: true)
  }

  private func buildRightActions(for indexPath: IndexPath) -> [FKSwipeActionItem] {
    let index = indexPath.row

    // Text only button with adaptive width.
    let editStyle = FKSwipeActionItemStyle(
      fixedWidth: nil,
      minimumWidth: 72,
      cornerRadius: 10,
      contentInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
      backgroundColor: .systemBlue,
      titleColor: .white,
      titleFont: .systemFont(ofSize: 14, weight: .semibold)
    )

    let edit = FKSwipeActionItem.edit(title: "Edit", style: editStyle) { [weak self] _ in
      self?.showToast("Edit tapped @ row \(index)")
    }

    // Image only button with fixed width.
    let pinStyle = FKSwipeActionItemStyle(
      fixedWidth: 62,
      cornerRadius: 10,
      contentInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
      backgroundColor: .systemOrange,
      imageTintColor: .white,
      imageSize: CGSize(width: 18, height: 18)
    )

    let pin = FKSwipeActionItem.pin(
      title: nil,
      image: UIImage(systemName: "pin.fill"),
      style: pinStyle
    ) { [weak self] _ in
      self?.showToast("Pin tapped @ row \(index)")
    }

    // Image + text button with adaptive width.
    let isFavorite = favoriteIndices.contains(index)
    let favoriteStyle = FKSwipeActionItemStyle(
      fixedWidth: nil,
      minimumWidth: 90,
      cornerRadius: 10,
      contentInsets: UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10),
      imageTitleSpacing: 4,
      backgroundColor: .systemPink,
      titleColor: .white,
      titleFont: .systemFont(ofSize: 13, weight: .bold),
      imageTintColor: .white,
      imageSize: CGSize(width: 16, height: 16)
    )

    let favorite = FKSwipeActionItem.favorite(
      title: isFavorite ? "Saved" : "Favorite",
      image: UIImage(systemName: isFavorite ? "heart.fill" : "heart"),
      style: favoriteStyle
    ) { [weak self] _ in
      guard let self else { return }
      if self.favoriteIndices.contains(index) {
        self.favoriteIndices.remove(index)
      } else {
        self.favoriteIndices.insert(index)
      }
      self.tableView.reloadRows(at: [indexPath], with: .none)
      self.showToast("Favorite toggled @ row \(index)")
    }

    // Dangerous delete with built-in confirmation.
    let deleteStyle = FKSwipeActionItemStyle(
      fixedWidth: 88,
      cornerRadius: 10,
      contentInsets: UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10),
      imageTitleSpacing: 4,
      backgroundColor: .systemRed,
      titleColor: .white,
      titleFont: .systemFont(ofSize: 13, weight: .bold),
      imageTintColor: .white,
      imageSize: CGSize(width: 16, height: 16)
    )

    let delete = FKSwipeActionItem.delete(
      title: "Delete",
      image: UIImage(systemName: "trash.fill"),
      requiresConfirmation: true,
      style: deleteStyle
    ) { [weak self] _ in
      guard let self, index < self.items.count else { return }
      self.items.remove(at: index)
      self.favoriteIndices = Set(self.favoriteIndices.compactMap { $0 > index ? $0 - 1 : ($0 == index ? nil : $0) })
      self.disabledIndices = Set(self.disabledIndices.compactMap { $0 > index ? $0 - 1 : ($0 == index ? nil : $0) })
      self.tableView.deleteRows(at: [indexPath], with: .automatic)
      self.showToast("Deleted row \(index + 1)")
    }

    return [edit, pin, favorite, delete]
  }

  private func showToast(_ message: String) {
    // Simple on-screen feedback to verify callback flow.
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak alert] in
      alert?.dismiss(animated: true)
    }
  }
}

// MARK: - UITableViewDataSource

extension FKSwipeActionTableExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = disabledIndices.contains(indexPath.row) ? "Swipe disabled for this row" : "Swipe right-to-left for actions"
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content

    // One-line setup API for right swipe multi-buttons.
    cell.fk_configureSwipeActions(right: buildRightActions(for: indexPath))
    cell.fk_setSwipeActionEnabled(!disabledIndices.contains(indexPath.row))

    return cell
  }
}

// MARK: - UITableViewDelegate

extension FKSwipeActionTableExampleViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    showToast("Tapped row \(indexPath.row + 1)")
  }
}
