import FKUIKit
import UIKit

/// RTL, semantic content, and custom accessibility strings — use this screen when validating global layout and VoiceOver copy.
final class FKProgressBarEnvironmentDemoViewController: UIViewController {

  private let bar = FKProgressBar()

  private lazy var rtlSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(rtlToggled), for: .valueChanged)
    return s
  }()

  private lazy var copyControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Default a11y", "EN label", "中文 标签"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(copyPresetChanged), for: .valueChanged)
    return c
  }()

  private lazy var hintControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["No hint", "EN hint", "中文 提示"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(copyPresetChanged), for: .valueChanged)
    return c
  }()

  private lazy var progressSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 1
    s.value = 0.35
    s.addTarget(self, action: #selector(progressChanged), for: .valueChanged)
    return s
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & accessibility"
    view.backgroundColor = .systemGroupedBackground

    let rtlRow = FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Force RTL on this screen", control: rtlSwitch)
    let copyRow = FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Accessibility label", control: copyControl)
    let hintRow = FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Accessibility hint", control: hintControl)
    let sliderRow = FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Progress", control: progressSlider)

    let card = FKProgressBarExampleLayoutHelpers.makeCardStack(arrangedSubviews: [
      FKProgressBarExampleLayoutHelpers.makeCaptionLabel(
        "When RTL is on, the view’s semanticContentAttribute is forced so leading/trailing progress matches reader direction. VoiceOver reads accessibilityLabel / accessibilityValue from the bar."
      ),
      bar,
      rtlRow,
      copyRow,
      hintRow,
      sliderRow,
    ])
    bar.translatesAutoresizingMaskIntoConstraints = false
    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      bar.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
    ])

    applyBaseConfiguration()
    copyPresetChanged()
    progressChanged()
  }

  private func applyBaseConfiguration() {
    var c = FKProgressBarConfiguration()
    c.appearance.showsBuffer = true
    c.label.placement = .below
    c.label.format = .percentInteger
    c.accessibility.treatAsFrequentUpdates = true
    bar.configuration = c
  }

  @objc private func rtlToggled() {
    view.semanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
  }

  @objc private func copyPresetChanged() {
    var c = bar.configuration
    switch copyControl.selectedSegmentIndex {
    case 1:
      c.accessibility.customLabel = "Download progress"
    case 2:
      c.accessibility.customLabel = "下载进度"
    default:
      c.accessibility.customLabel = nil
    }
    switch hintControl.selectedSegmentIndex {
    case 1:
      c.accessibility.customHint = "Double-tap and hold for more options in a real app."
    case 2:
      c.accessibility.customHint = "可在正式产品中连接自定义操作。"
    default:
      c.accessibility.customHint = nil
    }
    bar.configuration = c
  }

  @objc private func progressChanged() {
    let p = CGFloat(progressSlider.value)
    let b = min(1, p + 0.12)
    bar.setProgress(p, buffer: b, animated: true)
  }
}
