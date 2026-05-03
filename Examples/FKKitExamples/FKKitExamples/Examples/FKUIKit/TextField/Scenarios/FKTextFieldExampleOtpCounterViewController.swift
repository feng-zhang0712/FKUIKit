import UIKit
import FKUIKit

final class FKTextFieldExampleOtpCounterViewController: FKTextFieldExamplePageViewController {
  private weak var firstFocusableCodeInput: UIView?
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "OTP & Counter"
    build()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    firstFocusableCodeInput?.becomeFirstResponder()
  }

  private func build() {
    addSection(title: "OTP (FKTextField)", note: "Allows digits only; fixed length 6.")
    let otp = FKTextField(inputRule: FKTextFieldInputRule(formatType: .verificationCode(length: 6, allowsAlphabet: false), autoDismissKeyboardOnComplete: true))
    otp.placeholder = "Enter 6-digit verification code"
    let otpStatus = UILabel()
    otpStatus.text = "OTP callback: waiting for completion"
    otpStatus.textColor = .secondaryLabel
    otpStatus.font = .preferredFont(forTextStyle: .footnote)
    otp.onInputCompleted = { code in
      otpStatus.text = "OTP callback: \(code)"
    }
    addField(title: "OTP (FKTextField)", field: otp, ruleHint: "Allowed: digits only, fixed length = 6.")
    stack.addArrangedSubview(otpStatus)

    addSection(title: "OTP Slot Inputs", note: "Both slot fields allow digits only.")
    var c4 = FKCodeTextField.Configuration(length: 4, slotStyle: .underlines)
    c4.slotSpacing = 12
    let otp4 = FKCodeTextField(configuration: c4)
    otp4.translatesAutoresizingMaskIntoConstraints = false
    otp4.heightAnchor.constraint(equalToConstant: 52).isActive = true
    otp4.onCodeCompleted = { code in
      otpStatus.text = "OTP4 completed: \(code)"
    }
    firstFocusableCodeInput = otp4
    addCustomView(title: "OTP 4 (slot underlines)", view: otp4)

    var c6 = FKCodeTextField.Configuration(length: 6, slotStyle: .boxes)
    c6.slotSpacing = 10
    let otp6 = FKCodeTextField(configuration: c6)
    otp6.textContentType = .oneTimeCode
    otp6.translatesAutoresizingMaskIntoConstraints = false
    otp6.heightAnchor.constraint(equalToConstant: 52).isActive = true
    otp6.onCodeCompleted = { code in
      otpStatus.text = "OTP6 completed: \(code)"
      if code != "123456" {
        otp6.setErrorState(true, shakes: true)
      } else {
        otp6.setErrorState(false, shakes: false)
      }
    }
    addCustomView(title: "OTP 6 (slot boxes, AutoFill)", view: otp6)

    addSection(title: "TextView with Counter", note: "Allows general text input, with max-length enforcement and overflow callback.")
    let tv = FKCountTextView(configuration: FKCountTextView.Configuration(maxLength: 120, showsCounter: true, placeholder: "Enter text (max 120 characters)"))
    tv.font = .systemFont(ofSize: 15)
    let tvStatus = UILabel()
    tvStatus.text = "TextView callback: waiting for input"
    tvStatus.textColor = .secondaryLabel
    tvStatus.font = .preferredFont(forTextStyle: .footnote)
    tv.onTextChanged = { text in
      tvStatus.text = "TextView callback: \(text.count) chars"
    }
    tv.onOverflowAttempt = { _ in
      tvStatus.text = "TextView callback: overflow rejected"
    }
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.heightAnchor.constraint(equalToConstant: 120).isActive = true
    addCustomView(title: "TextView with Counter", view: tv)
    stack.addArrangedSubview(tvStatus)
  }
}
