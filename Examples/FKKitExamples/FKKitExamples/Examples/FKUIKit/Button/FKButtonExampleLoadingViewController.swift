import UIKit
import FKUIKit

final class FKButtonExampleLoadingViewController: FKButtonExampleBaseViewController {
  override var pageExplanationText: String? {
    "Loading examples cover overlay vs replace-content presentations and async helpers."
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addExampleSection(title: "Loading presentations", content: makeLoadingExamples())
  }

  private func makeLoadingExamples() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12

    let overlayBtn = FKButton()
    overlayBtn.content = .init(kind: .textAndImage(.leading))
    overlayBtn.setTitle(.init(text: "Overlay style", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    overlayBtn.setLeadingImage(.init(systemName: "arrow.down.circle.fill", tintColor: .white, spacingToTitle: 10), for: .normal)
    overlayBtn.setAppearances(.init(normal: .filled(backgroundColor: .systemBlue, cornerStyle: .init(corner: .fixed(12)))))
    overlayBtn.loadingPresentationStyle = .overlay(dimmedContentAlpha: 0.35)
    overlayBtn.loadingActivityIndicatorColor = .white
    overlayBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
    overlayBtn.widthAnchor.constraint(equalToConstant: 260).isActive = true
    overlayBtn.addAction(UIAction { [weak overlayBtn] _ in
      guard let overlayBtn else { return }
      Task { @MainActor in
        await overlayBtn.performWhileLoading(presentation: .overlay(dimmedContentAlpha: 0.3)) {
          try? await Task.sleep(nanoseconds: 1_100_000_000)
        }
      }
    }, for: .touchUpInside)

    let replaceBtn = FKButton()
    replaceBtn.content = .init(kind: .textAndImage(.leading))
    replaceBtn.setTitle(.init(text: "Hide + status text", font: .systemFont(ofSize: 15, weight: .semibold), color: .white), for: .normal)
    replaceBtn.setLeadingImage(.init(systemName: "icloud.and.arrow.down", tintColor: .white, spacingToTitle: 10), for: .normal)
    replaceBtn.setAppearances(.init(normal: .filled(backgroundColor: .systemIndigo, cornerStyle: .init(corner: .fixed(12)))))
    replaceBtn.loadingActivityIndicatorColor = .white
    replaceBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
    replaceBtn.widthAnchor.constraint(equalToConstant: 260).isActive = true
    replaceBtn.addAction(UIAction { [weak replaceBtn] _ in
      guard let replaceBtn else { return }
      Task { @MainActor in
        let options = FKButton.ReplacedContentLoadingOptions(
          spacingAfterIndicator: 10,
          message: "Processing...",
          messageFont: .systemFont(ofSize: 14, weight: .medium),
          messageColor: .white
        )
        await replaceBtn.performWhileLoading(presentation: .replacesContent(options)) {
          try? await Task.sleep(nanoseconds: 1_300_000_000)
        }
      }
    }, for: .touchUpInside)

    stack.addArrangedSubview(captionLabel("Use overlay or replace-content presentation while async work is running."))
    stack.addArrangedSubview(horizontallyCentered(overlayBtn))
    stack.addArrangedSubview(horizontallyCentered(replaceBtn))
    return stack
  }
}
