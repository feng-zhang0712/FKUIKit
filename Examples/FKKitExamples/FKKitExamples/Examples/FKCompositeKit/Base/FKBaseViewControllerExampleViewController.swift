//
// FKBaseViewControllerExampleViewController.swift
//

import UIKit
import FKCompositeKit

/// Demonstrates all major capabilities provided by `FKBaseViewController`.
final class FKBaseViewControllerExampleViewController: FKBaseViewController {
  private let stackView = UIStackView()
  private let keyboardField = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "BaseViewController"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "BackBtn",
      style: .plain,
      target: self,
      action: #selector(applyCustomBackButton)
    )
  }

  override func setupUI() {
    // Configure base options to showcase default capabilities.
    dismissKeyboardOnTapEnabled = true
    disableScrollViewBounceByDefault = true
    keyboardObservationEnabled = true
    navigationBarVisibility = .visible
    navigationBarStyle = .system
    logHandler = { event, params in
      print("[FKBaseVC Demo] \(event): \(params)")
    }

    stackView.axis = .vertical
    stackView.spacing = 12
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)

    keyboardField.borderStyle = .roundedRect
    keyboardField.placeholder = "Tap here, then tap blank area to dismiss keyboard"
    stackView.addArrangedSubview(keyboardField)

    let actions: [(String, Selector)] = [
      ("Show Loading (1.2s)", #selector(handleShowLoading)),
      ("Show Empty", #selector(handleShowEmpty)),
      ("Show Error + Retry", #selector(handleShowError)),
      ("Hide All State Views", #selector(handleHideAllStates)),
      ("Show Toast", #selector(handleShowToast)),
      ("Disable Full-Screen Pop", #selector(handleDisablePopGesture)),
      ("Enable Full-Screen Pop", #selector(handleEnablePopGesture)),
    ]
    actions.forEach { title, action in
      stackView.addArrangedSubview(makeButton(title: title, action: action))
    }
  }

  override func setupConstraints() {
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  override func setupBindings() {}

  override func keyboardWillChange(to frame: CGRect, duration: TimeInterval, curve: UIView.AnimationCurve) {
    showToast("Keyboard frame changed: \(Int(frame.height))")
  }

  override func keyboardWillHide(duration: TimeInterval, curve: UIView.AnimationCurve) {
    showToast("Keyboard hidden")
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.title = title
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  @objc private func applyCustomBackButton() {
    configureBackButton(title: "Back")
    showToast("Custom back button applied")
  }

  @objc private func handleShowLoading() {
    showLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.hideLoading()
    }
  }

  @objc private func handleShowEmpty() {
    showEmptyView(message: "No list data found. Pull to refresh or change filter.")
  }

  @objc private func handleShowError() {
    showErrorView(message: "Request failed, please try again.", retryTitle: "Retry") { [weak self] in
      self?.showToast("Retry callback triggered")
      self?.hideErrorView()
    }
  }

  @objc private func handleHideAllStates() {
    hideLoading()
    hideEmptyView()
    hideErrorView()
  }

  @objc private func handleShowToast() {
    showToast("This is a lightweight toast message from FKBaseViewController.")
  }

  @objc private func handleDisablePopGesture() {
    disablesInteractivePopGesture = true
    showToast("Full-screen pop gesture disabled")
  }

  @objc private func handleEnablePopGesture() {
    disablesInteractivePopGesture = false
    showToast("Full-screen pop gesture enabled")
  }
}
