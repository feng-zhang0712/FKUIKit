import UIKit
import FKUIKit

/// Shows `.fitContent` sizing and how it reacts to runtime content changes.
///
/// Key highlights:
/// - Starts at `.fitContent` and can expand.
/// - Explains why a max height fraction is important (prevents accidental full-screen growth).
final class SheetFitToContentExampleViewController: FKPresentationExamplePageViewController {
  private var maxFitFraction: Float = 0.9
  private var includesExtraBlocks: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Fit to content",
      subtitle: "A sheet that sizes itself to content with a safety cap.",
      notes: """
      Why a max height matters:
      - Prevents unexpected full-screen expansion when content grows.
      - Keeps the UI “sheet-like” while still being responsive.
      """
    )

    addView(
      FKExampleControls.slider(
        title: "Maximum fitContent height fraction",
        value: maxFitFraction,
        range: 0.4...1.0,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] v in
        self?.maxFitFraction = v
      }
    )

    addView(
      FKExampleControls.toggle(
        title: "Include extra content blocks",
        isOn: includesExtraBlocks
      ) { [weak self] isOn in
        self?.includesExtraBlocks = isOn
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let content = DynamicBlocksContentViewController(includesExtraBlocks: self.includesExtraBlocks)

      var configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fitContent, .full]
      configuration.sheet.maximumFitContentHeightFraction = CGFloat(self.maxFitFraction)

      FKPresentationController.present(
        contentController: content,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(),
        animated: true,
        completion: nil
      )
    }
  }
}

private final class DynamicBlocksContentViewController: UIViewController {
  private let includesExtraBlocks: Bool
  private let stack = UIStackView()

  init(includesExtraBlocks: Bool) {
    self.includesExtraBlocks = includesExtraBlocks
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    isExpanded = includesExtraBlocks

    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
    ])

    let title = UILabel()
    title.text = "Dynamic content"
    title.font = .preferredFont(forTextStyle: .title2)

    let subtitle = UILabel()
    subtitle.text = "Tap the button below to change the content height."
    subtitle.numberOfLines = 0
    subtitle.font = .preferredFont(forTextStyle: .body)
    subtitle.textColor = .secondaryLabel

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(subtitle)

    let toggleButton = UIButton(type: .system)
    toggleButton.configuration = .filled()
    toggleButton.configuration?.cornerStyle = .large
    toggleButton.setTitle("Toggle extra blocks", for: .normal)
    toggleButton.addAction(UIAction { [weak self] _ in
      self?.rebuildBlocks()
    }, for: .touchUpInside)
    stack.addArrangedSubview(toggleButton)

    rebuildBlocks(extra: includesExtraBlocks)
  }

  private var isExpanded = false

  private func rebuildBlocks() {
    isExpanded.toggle()
    rebuildBlocks(extra: isExpanded)
  }

  private func rebuildBlocks(extra: Bool) {
    // Remove existing blocks after the first 3 arranged subviews (title/subtitle/button).
    let fixedCount = 3
    while stack.arrangedSubviews.count > fixedCount {
      let v = stack.arrangedSubviews[fixedCount]
      stack.removeArrangedSubview(v)
      v.removeFromSuperview()
    }

    if extra {
      for idx in 1...8 {
        let label = UILabel()
        label.text = "Extra block \(idx)"
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.backgroundColor = .secondarySystemBackground
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stack.addArrangedSubview(label)
      }
    }

    // Encourage the presentation system to re-evaluate size if it uses preferredContentSize.
    view.setNeedsLayout()
    view.layoutIfNeeded()
    preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
  }
}

