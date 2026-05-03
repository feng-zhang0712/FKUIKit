import UIKit
import FKUIKit

/// All built-in `FKSkeletonPresets` factories.
final class FKSkeletonExamplePresetsViewController: UIViewController {

  private var presetContainers: [FKSkeletonContainerView] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presets"
    view.backgroundColor = .systemBackground

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Each preset returns a fully constrained FKSkeletonContainerView. listRow supports FKSkeletonAvatarStyle.circle and .rounded(...). textBlock reads defaultTextLineCount, lineSpacing, and lineHeight from the passed configuration; itemSpacing is available on FKSkeletonConfiguration for custom builders."
    ))

    let customPulse = FKSkeletonConfiguration(animationDuration: 0.9, animationMode: .pulse)

    addPreset(
      to: stack,
      title: "listRow · circle avatar",
      container: FKSkeletonPresets.listRow(
        avatarStyle: .circle,
        configuration: customPulse
      ),
      minHeight: 72
    )

    addPreset(
      to: stack,
      title: "listRow · rounded avatar",
      container: FKSkeletonPresets.listRow(
        avatarStyle: .rounded(cornerRadius: 10),
        configuration: nil
      ),
      minHeight: 72
    )

    addPreset(
      to: stack,
      title: "card",
      container: FKSkeletonPresets.card(configuration: nil),
      minHeight: 240
    )

    addPreset(
      to: stack,
      title: "textBlock · custom lineWidthRatios",
      container: FKSkeletonPresets.textBlock(
        lineCount: 5,
        lineWidthRatios: [1, 1, 0.92, 0.88, 0.5],
        configuration: nil
      ),
      minHeight: 120
    )

    var density = FKSkeletonConfiguration()
    density.defaultTextLineCount = 3
    density.lineSpacing = 14
    density.lineHeight = 11
    addPreset(
      to: stack,
      title: "textBlock · defaultTextLineCount / lineSpacing / lineHeight via configuration",
      container: FKSkeletonPresets.textBlock(lineCount: nil, configuration: density),
      minHeight: 72
    )

    addPreset(
      to: stack,
      title: "gridCell",
      container: FKSkeletonPresets.gridCell(configuration: nil),
      minHeight: 180
    )

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle show/hide",
      style: .plain,
      target: self,
      action: #selector(toggleVisible)
    )

    presetContainers.forEach { $0.showSkeleton(animated: false) }
    presetsShowing = true
  }

  private var presetsShowing = true

  private func addPreset(to stack: UIStackView, title: String, container: FKSkeletonContainerView, minHeight: CGFloat) {
    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader(title))
    container.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(container)
    container.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
    presetContainers.append(container)
  }

  @objc private func toggleVisible() {
    presetsShowing.toggle()
    if presetsShowing {
      presetContainers.forEach { $0.showSkeleton(animated: true) }
    } else {
      presetContainers.forEach { $0.hideSkeleton(animated: true) }
    }
  }
}
