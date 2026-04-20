//
// FKRefreshScrollViewDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// Non-list `UIScrollView` with tall stacked content to test header/footer placement.
//

import FKUIKit
import UIKit

final class FKRefreshScrollViewDemoViewController: UIViewController {

  private lazy var scrollView: UIScrollView = {
    let s = UIScrollView()
    s.translatesAutoresizingMaskIntoConstraints = false
    s.alwaysBounceVertical = true
    s.backgroundColor = .systemGroupedBackground
    return s
  }()

  private lazy var contentStack: UIStackView = {
    let st = UIStackView()
    st.axis = .vertical
    st.spacing = 12
    st.translatesAutoresizingMaskIntoConstraints = false
    return st
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIScrollView"
    view.backgroundColor = .systemGroupedBackground

    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
    ])

    let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue, .systemPurple]
    for i in 0..<18 {
      let block = UIView()
      block.backgroundColor = colors[i % colors.count].withAlphaComponent(0.35)
      block.layer.cornerRadius = 8
      block.translatesAutoresizingMaskIntoConstraints = false
      block.heightAnchor.constraint(equalToConstant: 72).isActive = true
      let lab = UILabel()
      lab.text = "Block \(i + 1) — scroll to test footer"
      lab.font = .preferredFont(forTextStyle: .headline)
      lab.translatesAutoresizingMaskIntoConstraints = false
      block.addSubview(lab)
      NSLayoutConstraint.activate([
        lab.centerXAnchor.constraint(equalTo: block.centerXAnchor),
        lab.centerYAnchor.constraint(equalTo: block.centerYAnchor),
      ])
      contentStack.addArrangedSubview(block)
    }

    var cfg = FKRefreshConfiguration()
    cfg.tintColor = .systemMint
    scrollView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 1.0) {
        self?.scrollView.fk_pullToRefresh?.endRefreshing()
        self?.scrollView.fk_loadMore?.resetToIdle()
      }
    }

    scrollView.fk_addLoadMore(configuration: cfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 0.8) {
        self?.scrollView.fk_loadMore?.endRefreshing()
      }
    }
  }
}
