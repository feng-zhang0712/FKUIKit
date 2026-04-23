import FKUIKit
import UIKit

final class FKRefreshComplexEnvironmentDemoViewController: UITabBarController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Complex Environments"

    let listA = FKRefreshLargeTitleKeyboardDemoViewController()
    listA.tabBarItem = UITabBarItem(title: "Large+Keyboard", image: UIImage(systemName: "text.cursor"), tag: 0)
    let navA = UINavigationController(rootViewController: listA)
    navA.navigationBar.prefersLargeTitles = true

    let listB = FKRefreshRotationTabDemoViewController()
    listB.tabBarItem = UITabBarItem(title: "Rotation", image: UIImage(systemName: "iphone.landscape"), tag: 1)
    let navB = UINavigationController(rootViewController: listB)
    navB.navigationBar.prefersLargeTitles = true

    viewControllers = [navA, navB]
  }
}

private final class FKRefreshLargeTitleKeyboardDemoViewController: UIViewController {
  private var items = (1...12).map { "Chat row \($0)" }

  private lazy var inputField: UITextField = {
    let field = UITextField()
    field.placeholder = "Tap to raise keyboard"
    field.borderStyle = .roundedRect
    field.translatesAutoresizingMaskIntoConstraints = false
    return field
  }()

  private lazy var tableView: UITableView = {
    let view = UITableView(frame: .zero, style: .insetGrouped)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.dataSource = self
    view.keyboardDismissMode = .interactive
    return view
  }()

  private var keyboardObserverTokens: [NSObjectProtocol] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Large Title + Keyboard"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.largeTitleDisplayMode = .always

    view.addSubview(inputField)
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      inputField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      tableView.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.fk_addPullToRefresh { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.8) {
        guard let self else { return }
        self.items = (1...12).map { "Refreshed row \($0)" }
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshing()
        self.tableView.fk_resetLoadMoreState()
      }
    }
    tableView.fk_addLoadMore { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.6) {
        guard let self else { return }
        let start = self.items.count + 1
        self.items.append(contentsOf: (start..<(start + 5)).map { "Chat row \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }

    bindKeyboardNotifications()
  }

  deinit {
    keyboardObserverTokens.forEach(NotificationCenter.default.removeObserver)
  }

  private func bindKeyboardNotifications() {
    let names: [Notification.Name] = [UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillHideNotification]
    keyboardObserverTokens = names.map { name in
      NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
        self?.handleKeyboard(note)
      }
    }
  }

  private func handleKeyboard(_ note: Notification) {
    guard
      let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
      let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
    else { return }
    let visibleH = max(0, view.convert(frame, from: nil).intersection(view.bounds).height)
    UIView.animate(withDuration: duration) {
      self.tableView.contentInset.bottom = visibleH
      self.tableView.scrollIndicatorInsets.bottom = visibleH
    }
  }
}

extension FKRefreshLargeTitleKeyboardDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = "Verify keyboard + large title inset stability."
    cell.contentConfiguration = content
    return cell
  }
}

private final class FKRefreshRotationTabDemoViewController: UIViewController {
  private var items = (1...18).map { "Rotation row \($0)" }

  private lazy var tableView: UITableView = {
    let view = UITableView(frame: .zero, style: .plain)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.dataSource = self
    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tab + Rotation"
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .always
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    var pull = FKRefreshConfiguration()
    pull.expandedHeight = 60
    tableView.fk_addPullToRefresh(configuration: pull) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.8) {
        self?.items.shuffle()
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
      }
    }
    tableView.fk_addLoadMore { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.5) {
        guard let self else { return }
        let start = self.items.count + 1
        self.items.append(contentsOf: (start..<(start + 8)).map { "Rotation row \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.tableView.reloadData()
    })
  }
}

extension FKRefreshRotationTabDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = "Rotate device quickly and verify refresh states remain valid."
    cell.contentConfiguration = content
    return cell
  }
}

