import UIKit
import FKUIKit

/// Performance test page: large dataset + FPS meter to validate smoothness.
final class FKSwipeActionPerformanceDemoViewController: UITableViewController {
  private var items: [Int] = Array(0..<400)
  private let fpsLabel = UILabel()
  private var meter: FKSwipeFPSMeter?
  private let headerContainer = UIView()
  private var lastHeaderWidth: CGFloat = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Performance (FPS)"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 56
    tableView.cellLayoutMarginsFollowReadableWidth = true

    // FPS meter (CADisplayLink).
    fpsLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    fpsLabel.textColor = .secondaryLabel
    fpsLabel.numberOfLines = 0
    fpsLabel.text =
      "FPS: --\n" +
      "Try: fast scrolling + repeated swipe open/close.\n" +
      "Goal: stay close to 60fps (device/simulator dependent)."
    configureHeaderIfNeeded()
    updateHeaderLayoutIfNeeded(force: true)

    meter = FKSwipeFPSMeter { [weak self] fps in
      guard let self else { return }
      self.fpsLabel.text =
        "FPS: \(fps)\n" +
        "Try: fast scrolling + repeated swipe open/close.\n" +
        "Goal: stay close to 60fps (device/simulator dependent)."
      // Update header height only when needed (avoid rebuilding header view repeatedly).
      self.updateHeaderLayoutIfNeeded(force: true)
    }
    meter?.start()

    // Key line: enable swipe actions with a realistic configuration (multiple buttons + corner + gradient).
    tableView.fk_enableSwipeActions { _ in
      FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "delete",
            title: "Delete",
            icon: UIImage(systemName: "trash.fill"),
            background: .color(.systemRed),
            layout: .iconTop,
            width: 86,
            cornerRadius: 14
          ) {},
          FKSwipeActionButton(
            id: "more",
            title: "More",
            icon: UIImage(systemName: "ellipsis"),
            background: .horizontalGradient(leading: .systemBlue, trailing: .systemTeal),
            layout: .iconLeading,
            width: 108,
            cornerRadius: 14
          ) {},
        ],
        allowsOnlyOneOpen: true,
        usesRubberBand: true
      )
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateHeaderLayoutIfNeeded(force: false)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    meter?.stop()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = "Row \(items[indexPath.row])"
    config.secondaryText = "Fast scroll + swipe (watch FPS)"
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.selectionStyle = .none
    return cell
  }

  private func configureHeaderIfNeeded() {
    guard tableView.tableHeaderView == nil else { return }
    headerContainer.backgroundColor = .clear
    fpsLabel.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(fpsLabel)
    NSLayoutConstraint.activate([
      fpsLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
      fpsLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
      fpsLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
      fpsLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),
    ])
    tableView.tableHeaderView = headerContainer
  }

  private func updateHeaderLayoutIfNeeded(force: Bool) {
    let width = view.bounds.width
    if !force, abs(width - lastHeaderWidth) < 0.5 { return }
    lastHeaderWidth = width
    let size = headerContainer.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
    tableView.tableHeaderView = headerContainer
  }
}

/// Minimal FPS meter (no third-party dependency).
private final class FKSwipeFPSMeter {
  private var link: CADisplayLink?
  private var lastTime: CFTimeInterval = 0
  private var frames: Int = 0
  private let onUpdate: (Int) -> Void

  init(onUpdate: @escaping (Int) -> Void) {
    self.onUpdate = onUpdate
  }

  func start() {
    guard link == nil else { return }
    lastTime = 0
    frames = 0
    let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
    link.add(to: .main, forMode: .common)
    self.link = link
  }

  func stop() {
    link?.invalidate()
    link = nil
  }

  @objc private func tick(_ link: CADisplayLink) {
    if lastTime == 0 {
      lastTime = link.timestamp
      return
    }
    frames += 1
    let delta = link.timestamp - lastTime
    if delta >= 1 {
      let fps = Int(round(Double(frames) / delta))
      frames = 0
      lastTime = link.timestamp
      onUpdate(max(0, min(120, fps)))
    }
  }
}

