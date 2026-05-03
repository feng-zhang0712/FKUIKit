import FKUIKit
import UIKit

/// Interactive surface for ``FKProgressBar`` — every major public option is exposed so integrators can validate combinations quickly.
///
/// - Note: Some combinations are unusual by design (e.g. segmented + ring); the bar clamps values internally.
final class FKProgressBarPlaygroundDemoViewController: UIViewController {

  private let previewBar = FKProgressBar()

  private lazy var scrollView: UIScrollView = {
    let s = UIScrollView()
    s.translatesAutoresizingMaskIntoConstraints = false
    s.alwaysBounceVertical = true
    return s
  }()

  private lazy var contentStack: UIStackView = {
    let s = UIStackView()
    s.translatesAutoresizingMaskIntoConstraints = false
    s.axis = .vertical
    s.spacing = 16
    return s
  }()

  // MARK: Controls

  private lazy var variantControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Linear", "Ring"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var axisControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Horizontal", "Vertical"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var themeControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["System", "Mint", "Sunset"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var fillControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Solid", "Gradient"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var progressSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 1
    s.value = 0.45
    s.addTarget(self, action: #selector(progressDragged), for: .valueChanged)
    return s
  }()

  private lazy var bufferSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 1
    s.value = 0.72
    s.addTarget(self, action: #selector(bufferDragged), for: .valueChanged)
    return s
  }()

  private lazy var bufferSwitch: UISwitch = {
    let s = UISwitch()
    s.isOn = true
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var indeterminateSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(indeterminateToggled), for: .valueChanged)
    return s
  }()

  private lazy var indeterminateStyleControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["None", "Marquee", "Breathe"])
    c.selectedSegmentIndex = 1
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var indeterminatePeriodSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = Float(0.35)
    s.maximumValue = Float(3)
    s.value = Float(1.35)
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var playsIndeterminateAnimSwitch: UISwitch = {
    let s = UISwitch()
    s.isOn = true
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var springSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var durationSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = Float(1.2)
    s.value = 0.25
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var timingControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Def", "Lin", "In", "Out", "IO"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var reducedMotionRespectSwitch: UISwitch = {
    let s = UISwitch()
    s.isOn = true
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var hapticControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["None", "Light", "Med", "Rigid"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var thicknessSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 2
    s.maximumValue = 22
    s.value = 6
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var ringWidthSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 2
    s.maximumValue = 14
    s.value = 5
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var ringDiameterSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 28
    s.maximumValue = 160
    s.value = 72
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var capControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Round", "Square"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var segmentSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 16
    s.value = 0
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var segmentGapSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = Float(0.35)
    s.value = Float(0.08)
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var trackBorderSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var progressBorderSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var labelPlacementControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["Off", "Above", "Below", "Lead", "Trail", "Center"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var labelFormatControl: UISegmentedControl = {
    let c = UISegmentedControl(items: ["% int", "% dec", "0–1", "Range"])
    c.selectedSegmentIndex = 0
    c.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return c
  }()

  private lazy var labelDigitsSlider: UISlider = {
    let s = UISlider()
    s.minimumValue = 0
    s.maximumValue = 4
    s.value = 1
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var semanticLabelColorSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var a11yFrequentSwitch: UISwitch = {
    let s = UISwitch()
    s.isOn = true
    s.addTarget(self, action: #selector(syncFromControls), for: .valueChanged)
    return s
  }()

  private lazy var logicalMinField: UITextField = {
    let t = UITextField()
    t.borderStyle = .roundedRect
    t.keyboardType = .decimalPad
    t.text = "0"
    t.addTarget(self, action: #selector(syncFromControls), for: .editingChanged)
    return t
  }()

  private lazy var logicalMaxField: UITextField = {
    let t = UITextField()
    t.borderStyle = .roundedRect
    t.keyboardType = .decimalPad
    t.text = "100"
    t.addTarget(self, action: #selector(syncFromControls), for: .editingChanged)
    return t
  }()

  private lazy var prefixField: UITextField = {
    let t = UITextField()
    t.borderStyle = .roundedRect
    t.placeholder = "prefix"
    t.addTarget(self, action: #selector(syncFromControls), for: .editingChanged)
    return t
  }()

  private lazy var suffixField: UITextField = {
    let t = UITextField()
    t.borderStyle = .roundedRect
    t.placeholder = "suffix"
    t.addTarget(self, action: #selector(syncFromControls), for: .editingChanged)
    return t
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"
    view.backgroundColor = .systemGroupedBackground
    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)

    let previewCard = FKProgressBarExampleLayoutHelpers.makeCardStack(arrangedSubviews: [
      FKProgressBarExampleLayoutHelpers.makeCaptionLabel(
        "Live preview — adjust controls below. Haptics fire when progress crosses 100% (if enabled) and completion haptic is not None."
      ),
      previewBar,
    ])
    previewBar.translatesAutoresizingMaskIntoConstraints = false

    let controlsCard = FKProgressBarExampleLayoutHelpers.makeCardStack(arrangedSubviews: buildControlRows())

    contentStack.addArrangedSubview(previewCard)
    contentStack.addArrangedSubview(controlsCard)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

      previewBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "0%", style: .plain, target: self, action: #selector(jumpZero)),
      UIBarButtonItem(title: "100%", style: .plain, target: self, action: #selector(jumpFull)),
      UIBarButtonItem(title: "Rand", style: .plain, target: self, action: #selector(jumpRandom)),
    ]

    let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
    tap.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(tap)

    syncFromControls()
  }

  private func buildControlRows() -> [UIView] {
    var rows: [UIView] = []
    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Variant & axis"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Variant", control: variantControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Axis (linear)", control: axisControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Theme", control: themeControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Fill", control: fillControl))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Progress & buffer"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Progress", control: progressSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Buffer", control: bufferSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Show buffer", control: bufferSwitch))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Indeterminate"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Enabled", control: indeterminateSwitch))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Style", control: indeterminateStyleControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Period (s)", control: indeterminatePeriodSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Animate indeterminate", control: playsIndeterminateAnimSwitch))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Motion"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Spring", control: springSwitch))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Duration", control: durationSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Timing", control: timingControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Respect reduce motion", control: reducedMotionRespectSwitch))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Completion haptic", control: hapticControl))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Geometry"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Track thickness", control: thicknessSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Ring line width", control: ringWidthSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Ring diameter", control: ringDiameterSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Linear cap", control: capControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Segments (0=off)", control: segmentSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Segment gap", control: segmentGapSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Track border", control: trackBorderSwitch))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Progress border", control: progressBorderSwitch))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Label"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Placement", control: labelPlacementControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Format", control: labelFormatControl))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Fraction digits", control: labelDigitsSlider))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Semantic label color", control: semanticLabelColorSwitch))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Logical range & copy"))
    let rangeRow = UIStackView(arrangedSubviews: [logicalMinField, logicalMaxField])
    rangeRow.spacing = 8
    rangeRow.distribution = .fillEqually
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Min / max", control: rangeRow))
    let affixRow = UIStackView(arrangedSubviews: [prefixField, suffixField])
    affixRow.spacing = 8
    affixRow.distribution = .fillEqually
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Prefix / suffix", control: affixRow))

    rows.append(FKProgressBarExampleLayoutHelpers.makeSectionLabel("Accessibility"))
    rows.append(FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Frequent updates trait", control: a11yFrequentSwitch))

    return rows
  }

  @objc private func endEditing() {
    view.endEditing(true)
  }

  @objc private func progressDragged() {
    previewBar.setProgress(CGFloat(progressSlider.value), animated: false)
  }

  @objc private func bufferDragged() {
    previewBar.setBufferProgress(CGFloat(bufferSlider.value), animated: false)
  }

  @objc private func indeterminateToggled() {
    previewBar.isIndeterminate = indeterminateSwitch.isOn
    syncFromControls()
  }

  @objc private func jumpZero() {
    progressSlider.value = 0
    previewBar.setProgress(0, animated: true)
  }

  @objc private func jumpFull() {
    progressSlider.value = 1
    previewBar.setProgress(1, animated: true)
  }

  @objc private func jumpRandom() {
    let v = Float.random(in: 0...1)
    progressSlider.value = v
    previewBar.setProgress(CGFloat(v), animated: true)
  }

  @objc private func syncFromControls() {
    var c = FKProgressBarConfiguration()
    c.layout.variant = variantControl.selectedSegmentIndex == 1 ? .ring : .linear
    c.layout.axis = axisControl.selectedSegmentIndex == 1 ? .vertical : .horizontal

    switch themeControl.selectedSegmentIndex {
    case 1:
      c.appearance.trackColor = UIColor(white: 0.25, alpha: 0.35)
      c.appearance.progressColor = .systemMint
      c.appearance.bufferColor = UIColor.systemMint.withAlphaComponent(0.35)
      c.appearance.progressGradientEndColor = .systemTeal
    case 2:
      c.appearance.trackColor = .tertiarySystemFill
      c.appearance.progressColor = .systemOrange
      c.appearance.bufferColor = UIColor.systemYellow.withAlphaComponent(0.45)
      c.appearance.progressGradientEndColor = .systemPink
    default:
      break
    }

    c.appearance.fillStyle = fillControl.selectedSegmentIndex == 1 ? .gradientAlongProgress : .solid
    c.appearance.showsBuffer = bufferSwitch.isOn
    c.motion.prefersSpringAnimation = springSwitch.isOn
    c.motion.animationDuration = TimeInterval(durationSlider.value)
    c.motion.timing = timingFromSegment(timingControl.selectedSegmentIndex)
    c.motion.respectsReducedMotion = reducedMotionRespectSwitch.isOn
    c.motion.completionHaptic = hapticFromSegment(hapticControl.selectedSegmentIndex)
    c.layout.trackThickness = CGFloat(thicknessSlider.value)
    c.layout.ringLineWidth = CGFloat(ringWidthSlider.value)
    c.layout.ringDiameter = CGFloat(ringDiameterSlider.value)
    c.layout.linearCapStyle = capControl.selectedSegmentIndex == 1 ? .square : .round
    c.layout.segmentCount = Int(segmentSlider.value.rounded())
    c.layout.segmentGapFraction = CGFloat(segmentGapSlider.value)
    c.appearance.trackBorderWidth = trackBorderSwitch.isOn ? 1 : 0
    c.appearance.trackBorderColor = .separator
    c.appearance.progressBorderWidth = progressBorderSwitch.isOn ? 1 : 0
    c.appearance.progressBorderColor = .label
    c.label.placement = labelPlacementFromSegment(labelPlacementControl.selectedSegmentIndex)
    c.label.format = labelFormatFromSegment(labelFormatControl.selectedSegmentIndex)
    c.label.fractionDigits = Int(labelDigitsSlider.value.rounded())
    c.label.usesSemanticTextColor = semanticLabelColorSwitch.isOn
    let lo = Double(logicalMinField.text ?? "") ?? 0
    var hi = Double(logicalMaxField.text ?? "") ?? 100
    if hi <= lo { hi = lo + 1 }
    c.label.logicalMinimum = lo
    c.label.logicalMaximum = hi
    c.label.valuePrefix = prefixField.text ?? ""
    c.label.valueSuffix = suffixField.text ?? ""
    c.accessibility.treatAsFrequentUpdates = a11yFrequentSwitch.isOn
    c.motion.indeterminateStyle = indeterminateStyleFromSegment(indeterminateStyleControl.selectedSegmentIndex)
    c.motion.indeterminatePeriod = TimeInterval(indeterminatePeriodSlider.value)
    c.motion.playsIndeterminateAnimation = playsIndeterminateAnimSwitch.isOn

    let isRing = c.layout.variant == .ring
    axisControl.isEnabled = !isRing
    capControl.isEnabled = !isRing
    segmentSlider.isEnabled = !isRing
    segmentGapSlider.isEnabled = !isRing && c.layout.segmentCount > 1

    previewBar.configuration = c
    previewBar.setProgress(CGFloat(progressSlider.value), buffer: CGFloat(bufferSlider.value), animated: false)
    previewBar.isIndeterminate = indeterminateSwitch.isOn
  }

  private func timingFromSegment(_ i: Int) -> FKProgressBarTiming {
    switch i {
    case 1: return .linear
    case 2: return .easeIn
    case 3: return .easeOut
    case 4: return .easeInOut
    default: return .default
    }
  }

  private func hapticFromSegment(_ i: Int) -> FKProgressBarCompletionHaptic {
    switch i {
    case 1: return .light
    case 2: return .medium
    case 3: return .rigid
    default: return .none
    }
  }

  private func labelPlacementFromSegment(_ i: Int) -> FKProgressBarLabelPlacement {
    switch i {
    case 1: return .above
    case 2: return .below
    case 3: return .leading
    case 4: return .trailing
    case 5: return .centeredOnTrack
    default: return .none
    }
  }

  private func labelFormatFromSegment(_ i: Int) -> FKProgressBarLabelFormat {
    switch i {
    case 1: return .percentFractional
    case 2: return .normalizedValue
    case 3: return .logicalRangeValue
    default: return .percentInteger
    }
  }

  private func indeterminateStyleFromSegment(_ i: Int) -> FKProgressBarIndeterminateStyle {
    switch i {
    case 1: return .marquee
    case 2: return .breathing
    default: return .none
    }
  }
}
