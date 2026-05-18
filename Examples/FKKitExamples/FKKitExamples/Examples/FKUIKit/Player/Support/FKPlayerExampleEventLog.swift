import UIKit

/// Append-only timestamped log for delegate and integration demos.
@MainActor
final class FKPlayerExampleEventLog {

  private(set) var lines: [String] = []

  func append(_ message: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    lines.append("[\(stamp)] \(message)")
    if lines.count > 200 {
      lines.removeFirst(lines.count - 200)
    }
  }

  func clear() {
    lines.removeAll()
  }

  var joinedText: String {
    lines.joined(separator: "\n")
  }

  func makeTextView() -> UITextView {
    let view = UITextView()
    view.isEditable = false
    view.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    view.backgroundColor = .secondarySystemGroupedBackground
    view.textColor = .label
    view.layer.cornerRadius = 8
    view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    view.text = joinedText
    return view
  }

  func refresh(_ textView: UITextView) {
    textView.text = joinedText
    let end = NSRange(location: max(0, joinedText.count - 1), length: 1)
    textView.scrollRangeToVisible(end)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}
