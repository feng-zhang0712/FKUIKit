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

  private lazy var toolBar: UIStackView = {
    let triggerLoadButton = UIButton(type: .system)
    triggerLoadButton.setTitle("Manual load more", for: .normal)
    triggerLoadButton.addTarget(self, action: #selector(triggerManualLoadMore), for: .touchUpInside)

    let toggleFooterButton = UIButton(type: .system)
    toggleFooterButton.setTitle("Toggle footer hidden", for: .normal)
    toggleFooterButton.addTarget(self, action: #selector(toggleFooterHidden), for: .touchUpInside)

    let bar = UIStackView(arrangedSubviews: [triggerLoadButton, toggleFooterButton])
    bar.axis = .horizontal
    bar.spacing = 12
    bar.distribution = .fillEqually
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIScrollView"
    view.backgroundColor = .systemGroupedBackground

    view.addSubview(toolBar)
    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      toolBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      scrollView.topAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 8),
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
    cfg.loadMoreTriggerMode = .manual
    scrollView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 1.0) {
        self?.scrollView.fk_pullToRefresh?.endRefreshing()
        self?.scrollView.fk_resetLoadMoreState()
      }
    }

    scrollView.fk_addLoadMore(configuration: cfg) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.8) {
        self?.scrollView.fk_loadMore?.endRefreshing()
      }
    }

    // Auto refresh when this screen is first shown.
    scrollView.fk_beginPullToRefresh(animated: true)
  }

  @objc private func triggerManualLoadMore() {
    // Manual mode keeps the footer off-screen until scrolled; scroll to bottom so the indicator is visible.
    scrollToBottomForLoadMore { [weak self] in
      self?.scrollView.fk_beginLoadMore()
    }
  }

  private func scrollToBottomForLoadMore(_ completion: @escaping () -> Void) {
    let s = scrollView
    s.layoutIfNeeded()
    let maxY = max(0, s.contentSize.height - s.bounds.height + s.adjustedContentInset.bottom)
    UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
      s.contentOffset = CGPoint(x: s.contentOffset.x, y: maxY)
    } completion: { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: completion)
    }
  }

  @objc private func toggleFooterHidden() {
    let nextHidden = !(scrollView.fk_loadMore?.isHidden ?? false)
    scrollView.fk_setLoadMoreHidden(nextHidden)
  }
}
