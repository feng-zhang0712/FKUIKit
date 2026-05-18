import UIKit

/// Scrollable synchronized lyrics display.
@MainActor
public final class FKAudioLyricsView: UIView {

  private let tableView = UITableView(frame: .zero, style: .plain)
  private var lines: [FKAudioLyricLine] = []
  private var highlightedIndex: Int?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    addSubview(tableView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    tableView.frame = bounds
  }

  public func setLines(_ lines: [FKAudioLyricLine]) {
    self.lines = lines
    highlightedIndex = nil
    tableView.reloadData()
    isHidden = lines.isEmpty
  }

  public func highlightLine(at index: Int?) {
    guard highlightedIndex != index else { return }
    let previous = highlightedIndex
    highlightedIndex = index
    var reload: [IndexPath] = []
    if let previous, lines.indices.contains(previous) {
      reload.append(IndexPath(row: previous, section: 0))
    }
    if let index, lines.indices.contains(index) {
      reload.append(IndexPath(row: index, section: 0))
      tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
    }
    if !reload.isEmpty {
      tableView.reloadRows(at: reload, with: .fade)
    }
  }
}

extension FKAudioLyricsView: UITableViewDataSource, UITableViewDelegate {

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    lines.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.backgroundColor = .clear
    cell.selectionStyle = .none
    cell.textLabel?.numberOfLines = 0
    cell.textLabel?.textAlignment = .center
    cell.textLabel?.text = lines[indexPath.row].text
    let active = indexPath.row == highlightedIndex
    cell.textLabel?.textColor = active ? .label : .secondaryLabel
    cell.textLabel?.font = active
      ? .systemFont(ofSize: 17, weight: .semibold)
      : .systemFont(ofSize: 15, weight: .regular)
    return cell
  }
}
