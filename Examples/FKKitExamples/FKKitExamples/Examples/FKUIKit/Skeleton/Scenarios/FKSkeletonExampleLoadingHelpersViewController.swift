import UIKit
import FKUIKit

/// `fk_setSkeletonLoading` and `fk_withSkeletonLoading` token semantics.
final class FKSkeletonExampleLoadingHelpersViewController: UIViewController {

  private let contentHost = FKSkeletonExampleLayout.borderedHostView()
  private let tokenLog = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Loading helpers"
    view.backgroundColor = .systemBackground

    let inner = UILabel()
    inner.text = "Async content region"
    inner.font = .preferredFont(forTextStyle: .title3)
    inner.textAlignment = .center
    inner.numberOfLines = 0
    inner.translatesAutoresizingMaskIntoConstraints = false
    contentHost.translatesAutoresizingMaskIntoConstraints = false
    contentHost.addSubview(inner)
    NSLayoutConstraint.activate([
      inner.topAnchor.constraint(equalTo: contentHost.topAnchor, constant: 24),
      inner.leadingAnchor.constraint(equalTo: contentHost.leadingAnchor, constant: 16),
      inner.trailingAnchor.constraint(equalTo: contentHost.trailingAnchor, constant: -16),
      inner.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor, constant: -24),
      contentHost.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
    ])

    tokenLog.font = .preferredFont(forTextStyle: .footnote)
    tokenLog.textColor = .secondaryLabel
    tokenLog.numberOfLines = 0
    tokenLog.text = "Tap “slow load” then “fast load”: only the latest completion hides skeleton."

    let stack = FKSkeletonExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKSkeletonExampleLayout.caption(
      "fk_setSkeletonLoading toggles manager-backed skeletons. fk_withSkeletonLoading issues a token so stale completions do not hide a newer load."
    ))
    stack.addArrangedSubview(contentHost)

    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("fk_setSkeletonLoading"))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Set loading true", primaryAction: UIAction { [weak self] _ in
      self?.contentHost.fk_setSkeletonLoading(true, animated: true)
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Set loading false", primaryAction: UIAction { [weak self] _ in
      self?.contentHost.fk_setSkeletonLoading(false, animated: true)
    }))

    stack.addArrangedSubview(FKSkeletonExampleLayout.sectionHeader("fk_withSkeletonLoading"))
    stack.addArrangedSubview(tokenLog)
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Slow load (2s)", primaryAction: UIAction { [weak self] _ in
      self?.beginTrackedLoad(delay: 2, label: "slow")
    }))
    stack.addArrangedSubview(FKSkeletonExampleLayout.primaryButton(title: "Fast load (0.4s)", primaryAction: UIAction { [weak self] _ in
      self?.beginTrackedLoad(delay: 0.4, label: "fast")
    }))
  }

  private func beginTrackedLoad(delay: TimeInterval, label: String) {
    appendLog("Started \(label) (\(delay)s)")
    contentHost.fk_withSkeletonLoading(animated: true) { [weak self] done in
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        self?.appendLog("Completion fired · \(label)")
        done()
      }
    }
  }

  private func appendLog(_ line: String) {
    let existing = tokenLog.text ?? ""
    let trimmed = existing.split(separator: "\n").suffix(4).joined(separator: "\n")
    tokenLog.text = ([String(trimmed), line].filter { !$0.isEmpty }).joined(separator: "\n")
  }
}
