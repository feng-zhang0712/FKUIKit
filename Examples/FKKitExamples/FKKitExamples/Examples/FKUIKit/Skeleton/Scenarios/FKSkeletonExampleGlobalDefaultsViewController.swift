import UIKit
import FKUIKit

/// Mutates `FKSkeleton.defaultConfiguration` with live preview; restores previous defaults when leaving.
final class FKSkeletonExampleGlobalDefaultsViewController: UIViewController {

  private var backup = FKSkeletonConfiguration()
  private let previewBlock = FKSkeletonView()

  private let modeControl = UISegmentedControl(items: ["Shimmer", "Pulse", "None"])
  private let durationSlider = UISlider()
  private let radiusSlider = UISlider()
  private let durationLabel = UILabel()
  private let radiusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global defaults"
    view.backgroundColor = .systemBackground

    backup = FKSkeleton.defaultConfiguration

    modeControl.selectedSegmentIndex = segmentIndex(for: backup.animationMode)

    durationSlider.minimumValue = 0.6
    durationSlider.maximumValue = 2.6
    durationSlider.value = Float(backup.animationDuration)

    radiusSlider.minimumValue = 0
    radiusSlider.maximumValue = 18
    radiusSlider.value = Float(backup.cornerRadius)

    previewBlock.layer.cornerRadius = CGFloat(radiusSlider.value)
    previewBlock.translatesAutoresizingMaskIntoConstraints = false
    previewBlock.heightAnchor.constraint(equalToConstant: 64).isActive = true

    durationLabel.font = .preferredFont(forTextStyle: .footnote)
    radiusLabel.font = .preferredFont(forTextStyle: .footnote)

    modeControl.addAction(UIAction { [weak self] _ in self?.applyGlobalsToDefaultsAndPreview() }, for: .valueChanged)
    durationSlider.addAction(UIAction { [weak self] _ in self?.applyGlobalsToDefaultsAndPreview() }, for: .valueChanged)
    radiusSlider.addAction(UIAction { [weak self] _ in self?.applyGlobalsToDefaultsAndPreview() }, for: .valueChanged)

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Changes apply immediately to FKSkeleton.defaultConfiguration. Other example pages see the new defaults until you leave this screen (values are restored automatically)."
    ))
    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("Live preview"))
    stack.addArrangedSubview(previewBlock)
    stack.addArrangedSubview(modeControl)
    stack.addArrangedSubview(durationLabel)
    stack.addArrangedSubview(durationSlider)
    stack.addArrangedSubview(radiusLabel)
    stack.addArrangedSubview(radiusSlider)
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Apply numbers to defaults now", primaryAction: UIAction { [weak self] _ in
      self?.applyGlobalsToDefaultsAndPreview()
    }))

    applyGlobalsToDefaultsAndPreview()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      FKSkeleton.defaultConfiguration = backup
    }
  }

  private func segmentIndex(for mode: FKSkeletonAnimationMode) -> Int {
    switch mode {
    case .shimmer: return 0
    case .pulse, .breathing: return 1
    case .none: return 2
    }
  }

  private func modeFromSegment() -> FKSkeletonAnimationMode {
    switch modeControl.selectedSegmentIndex {
    case 1: return .pulse
    case 2: return .none
    default: return .shimmer
    }
  }

  private func applyGlobalsToDefaultsAndPreview() {
    var cfg = FKSkeleton.defaultConfiguration
    cfg.animationMode = modeFromSegment()
    cfg.animationDuration = TimeInterval(durationSlider.value)
    cfg.cornerRadius = CGFloat(radiusSlider.value)
    cfg.inheritsCornerRadius = false
    FKSkeleton.defaultConfiguration = cfg

    durationLabel.text = String(format: "animationDuration: %.2fs", cfg.animationDuration)
    radiusLabel.text = String(format: "cornerRadius: %.0f pt", cfg.cornerRadius)

    previewBlock.layer.cornerRadius = cfg.cornerRadius
    previewBlock.configuration = nil
    previewBlock.show(animated: false)
  }
}
