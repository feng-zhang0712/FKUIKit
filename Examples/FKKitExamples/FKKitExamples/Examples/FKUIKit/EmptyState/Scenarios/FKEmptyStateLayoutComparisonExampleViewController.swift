import FKUIKit
import UIKit

final class FKEmptyStateLayoutComparisonExampleViewController: UIViewController {
  private let fullPageContainer = UIView()
  private let sectionContainer = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Full Page vs Inline"
    view.backgroundColor = .systemBackground
    buildUI()
    render()
  }

  private func buildUI() {
    let stack = UIStackView(arrangedSubviews: [fullPageContainer, sectionContainer])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    sectionContainer.backgroundColor = .secondarySystemBackground
    sectionContainer.layer.cornerRadius = 12
    sectionContainer.clipsToBounds = true

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      fullPageContainer.heightAnchor.constraint(equalTo: stack.heightAnchor, multiplier: 0.58),
    ])
  }

  private func render() {
    var fullPage = FKEmptyStateExampleFactory.makeLongTextModel()
    fullPage.context = .fullPage
    fullPage.contentInsets = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
    fullPage.actions = FKEmptyStateActionSet()
    fullPage.isButtonHidden = true
    fullPageContainer.fk_applyEmptyState(fullPage)

    var inline = FKEmptyStateExampleFactory.makeBasicModel()
    inline.context = .section
    inline.title = "Inline section is empty"
    inline.description = "Use compact copy in cards or dashboard sections."
    inline.maxContentWidth = 250
    inline.imageSize = CGSize(width: 36, height: 36)
    inline.actions = FKEmptyStateActionSet()
    inline.isButtonHidden = true
    sectionContainer.fk_applyEmptyState(inline)
  }
}
