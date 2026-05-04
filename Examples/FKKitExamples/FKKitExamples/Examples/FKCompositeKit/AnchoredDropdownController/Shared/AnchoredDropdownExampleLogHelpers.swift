import UIKit

enum AnchoredDropdownExampleLogHelpers {
  private static func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: Date())
  }

  static func makeCallbackLogTextView() -> UITextView {
    let logView = UITextView()
    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.backgroundColor = UIColor.secondarySystemBackground
    logView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logView.layer.cornerRadius = 10
    logView.layer.masksToBounds = true
    return logView
  }

  /// Pins `logView` under `sibling` at the bottom of `container` and keeps `sibling` above for hit testing.
  static func installLogView(_ logView: UITextView, in container: UIView, below sibling: UIView, height: CGFloat = 180) {
    container.insertSubview(logView, belowSubview: sibling)
    NSLayoutConstraint.activate([
      logView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      logView.heightAnchor.constraint(equalToConstant: height),
    ])
    container.bringSubviewToFront(sibling)
  }

  static func appendLogLine(_ text: String, to logView: UITextView) {
    let line = "[\(timestamp())] \(text)"
    if logView.text?.isEmpty ?? true {
      logView.text = line
    } else {
      logView.text = (logView.text ?? "") + "\n" + line
    }
    let range = NSRange(location: max(0, logView.text.count - 1), length: 1)
    logView.scrollRangeToVisible(range)
  }
}
