//
// FKRefreshCollectionDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// `UICollectionView` + pull / load-more (same `UIScrollView` APIs).
//

import FKUIKit
import UIKit

final class FKRefreshCollectionDemoViewController: UIViewController {

  private enum LoadOutcome: Int {
    case success
    case noMore
    case failed
  }

  private var items = (0..<24).map { "Cell \($0)" }
  private let maxItems = 48

  private lazy var layout: UICollectionViewFlowLayout = {
    let l = UICollectionViewFlowLayout()
    l.minimumInteritemSpacing = 8
    l.minimumLineSpacing = 8
    l.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    return l
  }()

  private lazy var collectionView: UICollectionView = {
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.translatesAutoresizingMaskIntoConstraints = false
    cv.backgroundColor = .systemGroupedBackground
    cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
    cv.dataSource = self
    cv.delegate = self
    return cv
  }()

  private lazy var outcomeControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Success", "No more", "Failed"])
    control.selectedSegmentIndex = 0
    return control
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CollectionView"
    view.backgroundColor = .systemGroupedBackground
    outcomeControl.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(outcomeControl)
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      outcomeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      outcomeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outcomeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      collectionView.topAnchor.constraint(equalTo: outcomeControl.bottomAnchor, constant: 8),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    var cfg = FKRefreshConfiguration()
    cfg.tintColor = .systemRed
    collectionView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 1.0) {
        self?.items = (0..<24).map { "Refreshed \($0)" }
        self?.collectionView.reloadData()
        self?.collectionView.fk_pullToRefresh?.endRefreshing()
        self?.collectionView.fk_resetLoadMoreState()
      }
    }

    collectionView.fk_addLoadMore(configuration: cfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 0.9) {
        guard let self else { return }
        let outcome = LoadOutcome(rawValue: self.outcomeControl.selectedSegmentIndex) ?? .success
        if outcome == .failed {
          self.collectionView.fk_loadMore?.endRefreshingWithError()
          return
        }
        if outcome == .noMore || self.items.count >= self.maxItems {
          self.collectionView.fk_loadMore?.endRefreshingWithNoMoreData()
          return
        }
        let n = self.items.count
        self.items.append(contentsOf: (n..<(n + 8)).map { "More \($0)" })
        self.collectionView.reloadData()
        self.collectionView.fk_loadMore?.endRefreshing()
      }
    }

    // Auto trigger pull-to-refresh to demonstrate one-line startup loading.
    collectionView.fk_beginPullToRefresh(animated: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let w = collectionView.bounds.width - 32 - 8
    let side = max(100, floor(w / 2))
    layout.itemSize = CGSize(width: side, height: 72)
  }
}

extension FKRefreshCollectionDemoViewController: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath)
    var c = UIListContentConfiguration.cell()
    c.text = items[indexPath.item]
    c.textProperties.font = .preferredFont(forTextStyle: .caption1)
    cell.contentConfiguration = c
    cell.backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    return cell
  }
}
