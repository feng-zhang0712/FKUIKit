import FKUIKit
import UIKit

final class FKRefreshLocalizationAccessibilityDemoViewController: UIViewController {
  private enum LocaleMode: Int {
    case english
    case arabic
  }

  private var items = (1...10).map { "Accessibility row \($0)" }

  private lazy var tableView: UITableView = {
    let view = UITableView(frame: .zero, style: .insetGrouped)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.dataSource = self
    return view
  }()

  private lazy var localeControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["English", "Arabic"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(localeChanged), for: .valueChanged)
    return control
  }()

  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.textColor = .secondaryLabel
    label.text = "Goal: validate i18n strings + Dynamic Type + VoiceOver announcements."
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "i18n + Accessibility"
    view.backgroundColor = .systemGroupedBackground

    let stack = UIStackView(arrangedSubviews: [localeControl, statusLabel])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      tableView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    installRefresh()
  }

  @objc
  private func localeChanged() {
    tableView.fk_pullToRefresh?.cancelCurrentAction(resetState: true)
    tableView.fk_loadMore?.cancelCurrentAction(resetState: true)
    tableView.fk_removeRefreshComponents()
    installRefresh()
    tableView.setContentOffset(.zero, animated: false)
  }

  private func installRefresh() {
    var config = FKRefreshConfiguration()
    config.texts = selectedTexts
    config.tintColor = .systemBlue
    config.loadMorePreloadOffset = 120

    tableView.semanticContentAttribute = localeControl.selectedSegmentIndex == LocaleMode.arabic.rawValue ? .forceRightToLeft : .forceLeftToRight

    tableView.fk_addPullToRefresh(configuration: config) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.8) {
        guard let self else { return }
        self.items = (1...10).map { "Accessibility row \($0)" }
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshing()
      }
    }

    tableView.fk_addLoadMore(configuration: config) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.7) {
        guard let self else { return }
        if self.items.count > 26 {
          self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
          return
        }
        let start = self.items.count + 1
        self.items.append(contentsOf: (start..<(start + 6)).map { "Accessibility row \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }

  private var selectedTexts: FKRefreshText {
    let mode = LocaleMode(rawValue: localeControl.selectedSegmentIndex) ?? .english
    switch mode {
    case .english:
      return FKRefreshText(
        pullToRefresh: "Pull to refresh",
        releaseToRefresh: "Release to refresh",
        headerLoading: "Refreshing data…",
        headerFinished: "Refresh completed",
        headerListEmpty: "No content",
        headerFailed: "Refresh failed",
        footerLoading: "Loading more…",
        footerFinished: "Loaded",
        footerNoMoreData: "No more data",
        footerFailed: "Load failed",
        footerTapToRetry: "Tap retry"
      )
    case .arabic:
      return FKRefreshText(
        pullToRefresh: "اسحب للتحديث",
        releaseToRefresh: "اترك للتحديث",
        headerLoading: "جارٍ التحديث…",
        headerFinished: "اكتمل التحديث",
        headerListEmpty: "لا توجد بيانات",
        headerFailed: "فشل التحديث",
        footerLoading: "جارٍ تحميل المزيد…",
        footerFinished: "تم التحميل",
        footerNoMoreData: "لا مزيد من البيانات",
        footerFailed: "فشل التحميل",
        footerTapToRetry: "اضغط لإعادة المحاولة"
      )
    }
  }
}

extension FKRefreshLocalizationAccessibilityDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = "Switch language and test VoiceOver + large text."
    content.textProperties.adjustsFontForContentSizeCategory = true
    content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
    cell.contentConfiguration = content
    return cell
  }
}

