import UIKit
import FKUIKit

/// Individual `FKSkeletonView` instances demonstrating configuration surface area.
final class FKSkeletonExampleStandaloneBlocksViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Standalone blocks"
    view.backgroundColor = .systemBackground

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Each row is an independent FKSkeletonView with a distinct FKSkeletonConfiguration (animation mode, shimmer direction, gradient, border, breathingMinOpacity, inheritsCornerRadius)."
    ))

    func addRow(title: String, block: FKSkeletonView, height: CGFloat = 52) {
      stack.addArrangedSubview(FKSkeletonExampleLayout.caption(title))
      block.translatesAutoresizingMaskIntoConstraints = false
      stack.addArrangedSubview(block)
      block.heightAnchor.constraint(equalToConstant: height).isActive = true
      block.show(animated: false)
    }

    var solid = FKSkeletonConfiguration()
    solid.animationMode = .none
    solid.style = .solid
    let solidBlock = FKSkeletonView()
    solidBlock.configuration = solid
    solidBlock.layer.cornerRadius = 8
    addRow(title: "animationMode .none · FKSkeletonStyle.solid", block: solidBlock)

    var shimmer = FKSkeletonConfiguration()
    shimmer.animationMode = .shimmer
    shimmer.shimmerDirection = .leftToRight
    let shimmerBlock = FKSkeletonView()
    shimmerBlock.configuration = shimmer
    shimmerBlock.layer.cornerRadius = 8
    addRow(title: "Shimmer · leftToRight", block: shimmerBlock)

    var shimmerRTL = FKSkeletonConfiguration()
    shimmerRTL.animationMode = .shimmer
    shimmerRTL.shimmerDirection = .rightToLeft
    let rtl = FKSkeletonView()
    rtl.configuration = shimmerRTL
    rtl.layer.cornerRadius = 8
    addRow(title: "Shimmer · rightToLeft", block: rtl)

    var shimmerTB = FKSkeletonConfiguration()
    shimmerTB.animationMode = .shimmer
    shimmerTB.shimmerDirection = .topToBottom
    let tb = FKSkeletonView()
    tb.configuration = shimmerTB
    tb.layer.cornerRadius = 8
    addRow(title: "Shimmer · topToBottom", block: tb)

    var shimmerBT = FKSkeletonConfiguration()
    shimmerBT.animationMode = .shimmer
    shimmerBT.shimmerDirection = .bottomToTop
    let bt = FKSkeletonView()
    bt.configuration = shimmerBT
    bt.layer.cornerRadius = 8
    addRow(title: "Shimmer · bottomToTop", block: bt)

    var diag = FKSkeletonConfiguration()
    diag.animationMode = .shimmer
    diag.shimmerDirection = .diagonal
    let dg = FKSkeletonView()
    dg.configuration = diag
    dg.layer.cornerRadius = 8
    addRow(title: "Shimmer · diagonal", block: dg)

    var pulse = FKSkeletonConfiguration()
    pulse.animationMode = .pulse
    pulse.style = .pulse
    pulse.breathingMinOpacity = 0.25
    let pulseBlock = FKSkeletonView()
    pulseBlock.configuration = pulse
    pulseBlock.layer.cornerRadius = 8
    addRow(title: "Pulse · breathingMinOpacity 0.25", block: pulseBlock)

    var breath = FKSkeletonConfiguration()
    breath.animationMode = .breathing
    let breathBlock = FKSkeletonView()
    breathBlock.configuration = breath
    breathBlock.layer.cornerRadius = 8
    addRow(title: "Breathing (alias of pulse-style)", block: breathBlock)

    var gradientCustom = FKSkeletonConfiguration()
    gradientCustom.gradientColors = [
      .systemBlue.withAlphaComponent(0.25),
      .systemCyan.withAlphaComponent(0.85),
      .systemBlue.withAlphaComponent(0.25),
    ]
    gradientCustom.animationMode = .shimmer
    let gradBlock = FKSkeletonView()
    gradBlock.configuration = gradientCustom
    gradBlock.layer.cornerRadius = 8
    addRow(title: "gradientColors override", block: gradBlock)

    var bordered = FKSkeletonConfiguration()
    bordered.borderWidth = 1
    bordered.animationMode = .shimmer
    let borderBlock = FKSkeletonView()
    borderBlock.configuration = bordered
    borderBlock.layer.cornerRadius = 8
    addRow(title: "borderWidth", block: borderBlock)

    var inheritOff = FKSkeletonConfiguration()
    inheritOff.inheritsCornerRadius = false
    inheritOff.cornerRadius = 4
    inheritOff.animationMode = .shimmer
    let inheritBlock = FKSkeletonView()
    inheritBlock.configuration = inheritOff
    inheritBlock.layer.cornerRadius = 18
    addRow(title: "inheritsCornerRadius false (uses config.cornerRadius 4, not layer 18)", block: inheritBlock)

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide all rows", primaryAction: UIAction { [weak self] _ in
      self?.hideAll(in: stack)
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show all rows", primaryAction: UIAction { [weak self] _ in
      self?.showAll(in: stack)
    }))
  }

  private func hideAll(in stack: UIStackView) {
    for case let block as FKSkeletonView in stack.arrangedSubviews {
      block.hide(animated: true)
    }
  }

  private func showAll(in stack: UIStackView) {
    for case let block as FKSkeletonView in stack.arrangedSubviews {
      block.show(animated: true)
    }
  }
}
