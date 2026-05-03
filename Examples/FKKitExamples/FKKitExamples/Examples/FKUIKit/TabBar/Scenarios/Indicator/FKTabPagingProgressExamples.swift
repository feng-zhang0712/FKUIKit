import UIKit
import FKUIKit

/// Demonstrates indicator styles and driving `FKTabBar` with external paging progress.
///
/// Key points:
/// - `FKTabBar` is UI-only and does not manage any pager/controller.
/// - A real app computes `progress` from a scroll view and calls `setSelectionProgress(from:to:progress:)`.
/// - This page uses a slider to simulate that progress input.
final class FKTabBarPagingProgressExampleViewController: UIViewController {
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(8), selectedIndex: 0)
  private var configuration = FKTabBarConfiguration()
  private let slider = UISlider()
  private let fromToLabel = UILabel()
  private var fromIndex: Int = 0
  private var toIndex: Int = 1
  private let styleControl = UISegmentedControl(items: ["Underline", "Pill"])
  private let fromStepper = UIStepper()
  private let toStepper = UIStepper()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indicator progress"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Indicator: underline/pill + external progress input"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Use the slider to drive setSelectionProgress(from:to:progress:). In real apps, this progress comes from an external pager scroll view. FKTabBar does not own any paging controller."))

    styleControl.selectedSegmentIndex = 0
    styleControl.addAction(UIAction { [weak self] _ in
      self?.applyIndicatorStyle()
    }, for: .valueChanged)
    stack.addArrangedSubview(styleControl)

    fromToLabel.font = .preferredFont(forTextStyle: .body)
    fromToLabel.numberOfLines = 0
    fromToLabel.text = "from: 0 → to: 1"
    stack.addArrangedSubview(fromToLabel)

    let fromRow = makeStepperRow(title: "From", stepper: fromStepper, initial: Double(fromIndex), onChange: { [weak self] value in
      guard let self else { return }
      self.fromIndex = Int(value)
      if self.toIndex == self.fromIndex { self.toIndex = min(7, self.fromIndex + 1) }
      self.syncSteppersAndLabel(resetProgress: true)
    })
    stack.addArrangedSubview(fromRow)

    let toRow = makeStepperRow(title: "To", stepper: toStepper, initial: Double(toIndex), onChange: { [weak self] value in
      guard let self else { return }
      self.toIndex = Int(value)
      if self.toIndex == self.fromIndex { self.fromIndex = max(0, self.toIndex - 1) }
      self.syncSteppersAndLabel(resetProgress: true)
    })
    stack.addArrangedSubview(toRow)

    let buttons = UIStackView()
    buttons.axis = .horizontal
    buttons.spacing = 8
    buttons.distribution = .fillEqually
    buttons.addArrangedSubview(FKTabBarExampleSupport.actionButton("Set pair (0→1)") { [weak self] in
      self?.setPair(from: 0, to: 1)
    })
    buttons.addArrangedSubview(FKTabBarExampleSupport.actionButton("Set pair (3→4)") { [weak self] in
      self?.setPair(from: 3, to: 4)
    })
    stack.addArrangedSubview(buttons)

    slider.minimumValue = 0
    slider.maximumValue = 1
    slider.value = 0
    slider.addAction(UIAction { [weak self] action in
      guard let self, let s = action.sender as? UISlider else { return }
      self.tabView.setSelectionProgress(from: self.fromIndex, to: self.toIndex, progress: CGFloat(s.value))
    }, for: .valueChanged)
    stack.addArrangedSubview(slider)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 56),
    ])

    // Configure steppers after view is set up.
    fromStepper.minimumValue = 0
    fromStepper.maximumValue = 7
    fromStepper.stepValue = 1
    toStepper.minimumValue = 0
    toStepper.maximumValue = 7
    toStepper.stepValue = 1
    syncSteppersAndLabel(resetProgress: false)
    applyIndicatorStyle()

    // Discrete switching animation: tap tabs to change selected index.
    tabView.onSelectionChanged = { [weak self] _, idx, reason in
      guard let self else { return }
      self.fromIndex = idx
      self.toIndex = min(7, idx + 1)
      self.syncSteppersAndLabel(resetProgress: reason == .userTap)
    }
  }

  private func applyIndicatorStyle() {
    // The component supports multiple indicator styles; this page keeps it minimal:
    // underline for classic tabs and pill for background highlight.
    if styleControl.selectedSegmentIndex == 1 {
      configuration.appearance.indicatorStyle = .pill(
        FKTabBarBackgroundIndicatorConfiguration(
          insets: .init(top: 6, leading: 8, bottom: 6, trailing: 8),
          cornerRadius: 999,
          fill: .solid(.secondarySystemFill)
        )
      )
    } else {
      configuration.appearance.indicatorStyle = .line(
        FKTabBarLineIndicatorConfiguration(
          position: .bottom,
          thickness: 3,
          fill: .solid(.systemBlue),
          leadingInset: 10,
          trailingInset: 10,
          cornerRadius: 1.5,
          followMode: .trackContentProgress
        )
      )
    }
    tabView.configuration = configuration
  }

  private func setPair(from: Int, to: Int) {
    fromIndex = max(0, min(7, from))
    toIndex = max(0, min(7, to))
    if fromIndex == toIndex { toIndex = min(7, fromIndex + 1) }
    syncSteppersAndLabel(resetProgress: true)
    tabView.setSelectedIndex(fromIndex, animated: true, reason: .programmatic)
  }

  private func syncSteppersAndLabel(resetProgress: Bool) {
    fromStepper.value = Double(fromIndex)
    toStepper.value = Double(toIndex)
    fromToLabel.text = "from: \(fromIndex) → to: \(toIndex)"
    if resetProgress { slider.value = 0 }
  }

  private func makeStepperRow(title: String, stepper: UIStepper, initial: Double, onChange: @escaping (Double) -> Void) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 10

    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .body)
    label.text = title
    row.addArrangedSubview(label)
    row.addArrangedSubview(UIView())

    stepper.value = initial
    stepper.addAction(UIAction { action in
      guard let s = action.sender as? UIStepper else { return }
      onChange(s.value)
    }, for: .valueChanged)
    row.addArrangedSubview(stepper)
    return row
  }
}

