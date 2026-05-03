import FKUIKit
import UIKit

/// Demonstrates ``FKProgressBarDelegate`` hooks for QA logging or host analytics pipelines.
final class FKProgressBarDelegateLogDemoViewController: UIViewController, FKProgressBarDelegate {

  private let bar = FKProgressBar()
  private let logView = UITextView()

  private lazy var progressSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 1
    s.value = 0.2
    s.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    return s
  }()

  private lazy var bufferSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 1
    s.value = 0.45
    s.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    return s
  }()

  private lazy var clearButton: UIBarButtonItem = {
    UIBarButtonItem(title: "Clear log", style: .plain, target: self, action: #selector(clearLog))
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate log"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.rightBarButtonItem = clearButton

    bar.delegate = self
    var c = FKProgressBarConfiguration()
    c.appearance.showsBuffer = true
    c.label.placement = .below
    c.label.format = .percentInteger
    c.motion.animationDuration = 0.35
    bar.configuration = c
    bar.translatesAutoresizingMaskIntoConstraints = false

    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    let sliderStack = UIStackView(arrangedSubviews: [
      FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Progress", control: progressSlider),
      FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Buffer", control: bufferSlider),
    ])
    sliderStack.axis = .vertical
    sliderStack.spacing = 8
    sliderStack.translatesAutoresizingMaskIntoConstraints = false

    let card = FKProgressBarExampleLayoutHelpers.makeCardStack(arrangedSubviews: [
      FKProgressBarExampleLayoutHelpers.makeCaptionLabel("Drag sliders — delegate methods append below with timestamps."),
      bar,
      sliderStack,
    ])

    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      bar.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

      logView.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    appendLine("viewDidLoad — ready")
    sliderChanged()
  }

  @objc private func sliderChanged() {
    bar.setProgress(CGFloat(progressSlider.value), buffer: CGFloat(bufferSlider.value), animated: true)
  }

  @objc private func clearLog() {
    logView.text = ""
  }

  private func appendLine(_ line: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    logView.text += "[\(ts)] \(line)\n"
    let bottom = NSRange(location: (logView.text as NSString).length - 1, length: 1)
    logView.scrollRangeToVisible(bottom)
  }

  // MARK: FKProgressBarDelegate

  func progressBar(_ progressBar: FKProgressBar, willAnimateProgress from: CGFloat, to: CGFloat, duration: TimeInterval) {
    appendLine("willAnimate \(String(format: "%.3f", from)) → \(String(format: "%.3f", to))  duration=\(String(format: "%.3f", duration))")
  }

  func progressBar(_ progressBar: FKProgressBar, didAnimateProgressTo value: CGFloat) {
    appendLine("didAnimate progress=\(String(format: "%.3f", value))")
  }

  func progressBar(_ progressBar: FKProgressBar, didChangeIndeterminate isIndeterminate: Bool) {
    appendLine("indeterminate=\(isIndeterminate)")
  }

  func progressBar(_ progressBar: FKProgressBar, didUpdateBufferProgress value: CGFloat) {
    appendLine("buffer=\(String(format: "%.3f", value))")
  }
}
