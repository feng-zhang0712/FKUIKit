import UIKit
import FKUIKit

/// Focused demo of ``FKSkeletonAnimationMode``, shimmer directions, palette, and live switching.
final class FKSkeletonExampleAnimationEffectsViewController: UIViewController {

  private let previewBlock = FKSkeletonView()
  private let modeControl = UISegmentedControl(items: ["Solid", "Shimmer", "Pulse", "Breathing"])
  private let directionControl = UISegmentedControl(items: ["L→R", "R→L", "↓", "↑", "Diag"])
  private let directionCaptionLabel = FKSkeletonExampleLayout.caption(
    "Direction applies when mode is Shimmer (`FKSkeletonShimmerDirection`)."
  )

  private let baseColorWell = UIColorWell()
  private let highlightColorWell = UIColorWell()

  private var customBaseColor: UIColor
  private var customHighlightColor: UIColor

  private var galleryBlocks: [FKSkeletonView] = []
  private var galleryTemplates: [FKSkeletonConfiguration] = []

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let cfg = FKSkeleton.defaultConfiguration
    customBaseColor = cfg.baseColor
    customHighlightColor = cfg.highlightColor
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    let cfg = FKSkeleton.defaultConfiguration
    customBaseColor = cfg.baseColor
    customHighlightColor = cfg.highlightColor
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Animation effects"
    view.backgroundColor = .systemBackground

    resolveColorsForCurrentTraits()

    modeControl.selectedSegmentIndex = 1
    directionControl.selectedSegmentIndex = 0

    previewBlock.translatesAutoresizingMaskIntoConstraints = false
    previewBlock.layer.cornerRadius = 12
    previewBlock.heightAnchor.constraint(equalToConstant: 72).isActive = true

    modeControl.addAction(UIAction { [weak self] _ in self?.applyPreviewConfiguration() }, for: .valueChanged)
    directionControl.addAction(UIAction { [weak self] _ in self?.applyPreviewConfiguration() }, for: .valueChanged)

    configureColorWells()

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("Live preview"))
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Use the segments to drive `animationMode` and shimmer axis. Colors map to `FKSkeletonConfiguration.baseColor` and `highlightColor` (default gradient stops when `gradientColors` is nil)."
    ))

    stack.addArrangedSubview(FKSkeletonExampleLayout.caption("Colors"))
    stack.addArrangedSubview(makeColorWellRow(label: "baseColor", well: baseColorWell))
    stack.addArrangedSubview(makeColorWellRow(label: "highlightColor", well: highlightColorWell))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Reset colors to FKSkeleton.defaultConfiguration", primaryAction: UIAction { [weak self] _ in
      self?.resetColorsToPackageDefaults()
    }))

    stack.addArrangedSubview(modeControl)
    stack.addArrangedSubview(directionCaptionLabel)
    stack.addArrangedSubview(directionControl)
    stack.addArrangedSubview(previewBlock)

    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("Side-by-side gallery"))
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Each row shares the same palette from the color wells above."
    ))

    addGalleryRow(to: stack, title: "Solid · animationMode .none") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .none
      return c
    }
    addGalleryRow(to: stack, title: "Shimmer · left → right") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .shimmer
      c.shimmerDirection = .leftToRight
      return c
    }
    addGalleryRow(to: stack, title: "Shimmer · right → left") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .shimmer
      c.shimmerDirection = .rightToLeft
      return c
    }
    addGalleryRow(to: stack, title: "Shimmer · top → bottom") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .shimmer
      c.shimmerDirection = .topToBottom
      return c
    }
    addGalleryRow(to: stack, title: "Shimmer · bottom → top") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .shimmer
      c.shimmerDirection = .bottomToTop
      return c
    }
    addGalleryRow(to: stack, title: "Shimmer · diagonal") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .shimmer
      c.shimmerDirection = .diagonal
      return c
    }
    addGalleryRow(to: stack, title: "Pulse · animationMode .pulse") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .pulse
      c.animationDuration = 1.2
      return c
    }
    addGalleryRow(to: stack, title: "Breathing · alias of pulse-style motion") {
      var c = FKSkeletonConfiguration()
      c.animationMode = .breathing
      c.animationDuration = 1.2
      return c
    }

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Pause / resume all gallery blocks", primaryAction: UIAction { [weak self] _ in
      self?.toggleGalleryAnimations()
    }))

    applyPreviewConfiguration()
    syncDirectionVisibility()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
    syncWellsFromStoredColors()
    applyPreviewConfiguration()
    refreshGalleryPalette()
  }

  private func configureColorWells() {
    baseColorWell.supportsAlpha = false
    highlightColorWell.supportsAlpha = false
    syncWellsFromStoredColors()

    let paletteAction = UIAction { [weak self] _ in
      self?.onPaletteChanged()
    }
    baseColorWell.addAction(paletteAction, for: .valueChanged)
    highlightColorWell.addAction(paletteAction, for: .valueChanged)
  }

  private func syncWellsFromStoredColors() {
    baseColorWell.selectedColor = customBaseColor.resolvedColor(with: traitCollection)
    highlightColorWell.selectedColor = customHighlightColor.resolvedColor(with: traitCollection)
  }

  private func resolveColorsForCurrentTraits() {
    customBaseColor = customBaseColor.resolvedColor(with: traitCollection)
    customHighlightColor = customHighlightColor.resolvedColor(with: traitCollection)
  }

  private func onPaletteChanged() {
    if let b = baseColorWell.selectedColor {
      customBaseColor = b
    }
    if let h = highlightColorWell.selectedColor {
      customHighlightColor = h
    }
    applyPreviewConfiguration()
    refreshGalleryPalette()
  }

  private func resetColorsToPackageDefaults() {
    let cfg = FKSkeleton.defaultConfiguration
    customBaseColor = cfg.baseColor.resolvedColor(with: traitCollection)
    customHighlightColor = cfg.highlightColor.resolvedColor(with: traitCollection)
    syncWellsFromStoredColors()
    applyPreviewConfiguration()
    refreshGalleryPalette()
  }

  private func makeColorWellRow(label text: String, well: UIColorWell) -> UIStackView {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    well.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      well.widthAnchor.constraint(equalToConstant: 44),
      well.heightAnchor.constraint(equalToConstant: 44),
    ])
    let row = UIStackView(arrangedSubviews: [label, well])
    row.spacing = 12
    row.alignment = .center
    return row
  }

  private func configurationWithPalette(_ template: FKSkeletonConfiguration) -> FKSkeletonConfiguration {
    var c = template
    c.baseColor = customBaseColor
    c.highlightColor = customHighlightColor
    return c
  }

  private func makePreviewConfiguration() -> FKSkeletonConfiguration {
    var c = FKSkeletonConfiguration()
    c.animationDuration = 1.35
    c.baseColor = customBaseColor
    c.highlightColor = customHighlightColor
    switch modeControl.selectedSegmentIndex {
    case 0:
      c.animationMode = .none
    case 1:
      c.animationMode = .shimmer
      c.shimmerDirection = directionFromSegment()
    case 2:
      c.animationMode = .pulse
    default:
      c.animationMode = .breathing
    }
    return c
  }

  private func applyPreviewConfiguration() {
    previewBlock.configuration = makePreviewConfiguration()
    previewBlock.show(animated: false)
    syncDirectionVisibility()
  }

  private func directionFromSegment() -> FKSkeletonShimmerDirection {
    switch directionControl.selectedSegmentIndex {
    case 1: return .rightToLeft
    case 2: return .topToBottom
    case 3: return .bottomToTop
    case 4: return .diagonal
    default: return .leftToRight
    }
  }

  private func syncDirectionVisibility() {
    let shimmer = modeControl.selectedSegmentIndex == 1
    directionControl.isHidden = !shimmer
    directionCaptionLabel.isHidden = !shimmer
  }

  private func addGalleryRow(to stack: UIStackView, title: String, build: () -> FKSkeletonConfiguration) {
    let template = build()
    galleryTemplates.append(template)

    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(title))
    let block = FKSkeletonView()
    block.configuration = configurationWithPalette(template)
    block.translatesAutoresizingMaskIntoConstraints = false
    block.layer.cornerRadius = 8
    stack.addArrangedSubview(block)
    block.heightAnchor.constraint(equalToConstant: 48).isActive = true
    block.show(animated: false)
    galleryBlocks.append(block)
  }

  private func refreshGalleryPalette() {
    guard galleryBlocks.count == galleryTemplates.count else { return }
    for idx in galleryBlocks.indices {
      galleryBlocks[idx].configuration = configurationWithPalette(galleryTemplates[idx])
      galleryBlocks[idx].show(animated: false)
    }
  }

  private func toggleGalleryAnimations() {
    let anyHidden = galleryBlocks.contains { $0.isHidden }
    if anyHidden {
      galleryBlocks.forEach { $0.show(animated: true) }
    } else {
      galleryBlocks.forEach { $0.hide(animated: true) }
    }
  }
}
