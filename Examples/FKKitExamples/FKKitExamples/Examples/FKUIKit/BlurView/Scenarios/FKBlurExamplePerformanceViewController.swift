import UIKit
import FKUIKit

// MARK: - Scenario: Scroll Performance (60fps)

final class FKBlurPerformanceTestVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private var fpsItem: UIBarButtonItem?
  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scroll Performance"
    view.backgroundColor = .systemBackground

    // Performance test requirement:
    // - The dynamic blur effect must be applied inside each cell.
    // - Use the system backend (hardware materials) to validate smooth 60fps scrolling under real-world usage.
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.rowHeight = 92
    tableView.separatorStyle = .none
    tableView.register(FKBlurPerformanceCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Put the FPS readout in the navigation bar so it won't affect scrolling performance.
    let fps = UIBarButtonItem(title: "FPS: --", style: .plain, target: nil, action: nil)
    fps.isEnabled = false
    navigationItem.rightBarButtonItem = fps
    fpsItem = fps

    // Optional table header with a simple hint (not blurred).
    let header = UILabel()
    header.text = "Scroll fast to validate smoothness. Each cell contains a FKBlurView (system material)."
    header.numberOfLines = 0
    header.textColor = .secondaryLabel
    header.font = .preferredFont(forTextStyle: .footnote)
    header.textAlignment = .left
    header.backgroundColor = .clear
    header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
    tableView.tableHeaderView = header
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startFPSMonitor()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopFPSMonitor()
  }

  private func startFPSMonitor() {
    guard displayLink == nil else { return }
    lastTimestamp = 0
    frameCount = 0
    let link = CADisplayLink(target: self, selector: #selector(onTick))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func stopFPSMonitor() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func onTick(link: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = link.timestamp
      return
    }
    frameCount += 1
    let delta = link.timestamp - lastTimestamp
    if delta >= 1.0 {
      let fps = Double(frameCount) / delta
      fpsItem?.title = String(format: "FPS: %.0f", fps)
      lastTimestamp = link.timestamp
      frameCount = 0
    }
  }

  // MARK: UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 200 }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? FKBlurPerformanceCell else {
      return UITableViewCell()
    }
    cell.configure(row: indexPath.row)
    return cell
  }
}

// MARK: - Cell: Blur inside each row

/// A table view cell that contains a dynamic system-material `FKBlurView`.
///
/// This cell is purposely UI-only and reuse-friendly:
/// - A vivid background makes the blur effect easy to see.
/// - The blur view is created once and reused with the cell.
final class FKBlurPerformanceCell: UITableViewCell {
  private let card = UIView()
  private let gradient = CAGradientLayer()
  private let blurView = FKBlurView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func commonInit() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    card.translatesAutoresizingMaskIntoConstraints = false
    card.layer.cornerRadius = 14
    card.clipsToBounds = true
    contentView.addSubview(card)
    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
    ])

    gradient.colors = [
      UIColor.systemPink.cgColor,
      UIColor.systemPurple.cgColor,
      UIColor.systemBlue.cgColor,
      UIColor.systemTeal.cgColor,
    ]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    card.layer.insertSublayer(gradient, at: 0)

    // System-material backend is the highest-performance dynamic blur path.
    blurView.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
    blurView.maskedCornerRadius = 12
    blurView.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(blurView)
    NSLayoutConstraint.activate([
      blurView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
      blurView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      blurView.widthAnchor.constraint(equalToConstant: 160),
      blurView.heightAnchor.constraint(equalToConstant: 56),
    ])

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    card.addSubview(titleLabel)
    card.addSubview(subtitleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blurView.leadingAnchor, constant: -12),
      titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blurView.leadingAnchor, constant: -12),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
    ])
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Keep gradient frame in sync with the card bounds during scrolling and rotation.
    gradient.frame = card.bounds
  }

  func configure(row: Int) {
    titleLabel.text = "Row \(row)"
    subtitleLabel.text = "System material blur inside cell"
  }
}
