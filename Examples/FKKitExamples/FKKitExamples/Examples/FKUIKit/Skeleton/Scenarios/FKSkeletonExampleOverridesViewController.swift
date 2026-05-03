import UIKit
import FKUIKit

/// Per-view shape / configuration overrides and typed convenience entry points.
final class FKSkeletonExampleOverridesViewController: UIViewController {

  private let shapeHosts: [(String, FKSkeletonShape, UIView)] = {
    func box(_ shape: FKSkeletonShape) -> UIImageView {
      let v = UIImageView(image: UIImage(systemName: "person.crop.square.fill"))
      v.contentMode = .scaleAspectFill
      v.clipsToBounds = true
      v.backgroundColor = .tertiarySystemFill
      v.fk_skeletonShape = shape
      v.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        v.heightAnchor.constraint(equalToConstant: 56),
        v.widthAnchor.constraint(equalToConstant: 56),
      ])
      return v
    }
    return [
      ("rectangle", .rectangle, box(.rectangle)),
      ("circle", .circle, box(.circle)),
      ("rounded", .rounded, box(.rounded)),
      ("custom(10)", .custom(10), box(.custom(10))),
    ]
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Overrides & convenience"
    view.backgroundColor = .systemBackground

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("fk_skeletonShape (auto mode)"))
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "Each UIImageView uses a different fk_skeletonShape before fk_showAutoSkeleton."
    ))

    let shapeGrid = UIStackView()
    shapeGrid.axis = .vertical
    shapeGrid.spacing = 10
    for (name, _, host) in shapeHosts {
      let caption = UILabel()
      caption.font = .preferredFont(forTextStyle: .caption1)
      caption.textColor = .secondaryLabel
      caption.text = name
      let row = UIStackView(arrangedSubviews: [host, caption])
      row.spacing = 12
      row.alignment = .center
      shapeGrid.addArrangedSubview(row)
    }
    stack.addArrangedSubview(shapeGrid)

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Auto skeleton · shape row", primaryAction: UIAction { [weak self] _ in
      self?.shapeHosts.forEach { $0.2.fk_showAutoSkeleton(options: .init(hidesTargetView: true), animated: true) }
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide shape row", primaryAction: UIAction { [weak self] _ in
      self?.shapeHosts.forEach { $0.2.fk_hideAutoSkeleton(animated: true) }
    }))

    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("fk_skeletonConfigurationOverride"))
    let overrideLabel = UILabel()
    overrideLabel.text = "This label uses a warmer highlight override."
    overrideLabel.font = .preferredFont(forTextStyle: .body)
    overrideLabel.numberOfLines = 0
    var warm = FKSkeleton.defaultConfiguration
    warm.highlightColor = .systemOrange.withAlphaComponent(0.55)
    warm.animationMode = .pulse
    overrideLabel.fk_skeletonConfigurationOverride = warm

    stack.addArrangedSubview(overrideLabel)
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show override label skeleton", primaryAction: UIAction { _ in
      overrideLabel.fk_showAutoSkeleton(options: .init(hidesTargetView: true), animated: true)
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide override label skeleton", primaryAction: UIAction { _ in
      overrideLabel.fk_hideAutoSkeleton(animated: true)
    }))

    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("Convenience wrappers"))
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "fk_showSkeletonLabel / Image / Button / TextField map to auto skeleton with hidesTargetView."
    ))

    let convLabel = UILabel()
    convLabel.text = "Label"
    convLabel.font = .preferredFont(forTextStyle: .headline)

    let convImage = UIImageView(image: UIImage(systemName: "sparkles"))
    convImage.tintColor = .systemPurple
    convImage.contentMode = .scaleAspectFit
    convImage.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      convImage.heightAnchor.constraint(equalToConstant: 40),
    ])

    let convButton = UIButton(type: .system)
    convButton.setTitle("Button", for: .normal)

    let convField = UITextField()
    convField.borderStyle = .roundedRect
    convField.placeholder = "Text field"
    convField.font = .preferredFont(forTextStyle: .body)

    let convColumn = UIStackView(arrangedSubviews: [convLabel, convImage, convButton, convField])
    convColumn.axis = .vertical
    convColumn.spacing = 12
    stack.addArrangedSubview(convColumn)

    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Show convenience skeletons", primaryAction: UIAction { _ in
      convLabel.fk_showSkeletonLabel(animated: true)
      convImage.fk_showSkeletonImage(animated: true)
      convButton.fk_showSkeletonButton(animated: true)
      convField.fk_showSkeletonTextField(animated: true)
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Hide convenience skeletons", primaryAction: UIAction { _ in
      convLabel.fk_hideAutoSkeleton(animated: true)
      convImage.fk_hideAutoSkeleton(animated: true)
      convButton.fk_hideAutoSkeleton(animated: true)
      convField.fk_hideAutoSkeleton(animated: true)
    }))
  }
}
