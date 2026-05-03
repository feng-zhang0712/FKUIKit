import UIKit
import FKUIKit

final class FKTextFieldExampleKeyboardViewController: FKTextFieldExamplePageViewController {
  private var keyboardObserver: NSObjectProtocol?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Keyboard Interaction"
    build()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard keyboardObserver == nil else { return }
    keyboardObserver = NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      self?.keyboardWillChangeFrame(note)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let keyboardObserver {
      NotificationCenter.default.removeObserver(keyboardObserver)
      self.keyboardObserver = nil
    }
  }

  private func build() {
    addSection(title: "Keyboard Auto Offset", note: "Listen to keyboard frame changes and update scrollView insets.")
    for i in 1...8 {
      addField(
        title: "Input \(i)",
        field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Enter item \(i)"),
        ruleHint: "Allowed: A-Z, a-z, 0-9."
      )
    }
    addSection(title: "Tap Blank Area to Dismiss Keyboard", note: "This page already installs a tap gesture to end editing.")
  }

  private func keyboardWillChangeFrame(_ note: Notification) {
    guard let userInfo = note.userInfo,
          let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    let keyboardFrame = view.convert(endFrame, from: nil)
    let overlap = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
    scrollView.contentInset.bottom = overlap + 12
    scrollView.verticalScrollIndicatorInsets.bottom = overlap + 12
  }
}
