# FKTextField

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Supported Format Types](#supported-format-types)
- [Supported Validation Rules](#supported-validation-rules)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Create TextField with Code](#create-textfield-with-code)
  - [Create TextField with XIB/Storyboard](#create-textfield-with-xibstoryboard)
  - [Phone Number Format](#phone-number-format)
  - [ID Card Format](#id-card-format)
  - [Bank Card Format](#bank-card-format)
  - [Verification Code](#verification-code)
  - [Password Input](#password-input)
- [Advanced Usage](#advanced-usage)
  - [Custom Input Limit & Length](#custom-input-limit--length)
  - [Custom Style (Placeholder, Border, Color)](#custom-style-placeholder-border-color)
  - [Input Validation & Error Tip](#input-validation--error-tip)
  - [Left/Right View Customization](#leftright-view-customization)
  - [Secure Text Toggle & Clear Button](#secure-text-toggle--clear-button)
  - [Global Style Configuration](#global-style-configuration)
  - [Custom Regex Format](#custom-regex-format)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Performance Optimization](#performance-optimization)
- [Notes](#notes)
- [License](#license)

This document is organized from quick understanding to hands-on integration. If you are new to `FKTextField`, start with **Overview** and **Features**, then jump to **Basic Usage** for copy-ready examples. For production integration, review **Advanced Usage**, **Best Practices**, and **Performance Optimization**.

## Overview
`FKTextField` is a production-ready formatted input component implemented as a native `UITextField` subclass.

It is designed for iOS apps and UI libraries that need:
- zero third-party dependencies,
- a protocol-oriented, testable architecture,
- one-line format rule configuration,
- realtime filtering, formatting, and validation,
- reusable-list friendly behavior with predictable rendering.

The component is built with UIKit/Foundation only and covers common business scenarios such as phone number, ID card, bank card, OTP, password, amount, email, and custom regex-driven input.

## Features
- Pure native Swift implementation based on UIKit/Foundation.
- Non-invasive design (`UITextField` subclass), compatible with code/XIB/Storyboard.
- Built-in formatter pipeline with automatic spacing/grouping and illegal character filtering.
- Built-in validator pipeline with structured validation result and error message.
- Strong input control:
  - max length limit,
  - whitespace/emoji/special character control,
  - debounce callback support,
  - anti-burst input interval (`minimumInputInterval`).
- Full style customization:
  - placeholder and attributed placeholder,
  - border/corner/background/shadow for normal/focused/error states,
  - clear button and password visibility toggle.
- Business-friendly callbacks:
  - text change callback (raw + formatted),
  - formatting callback,
  - validation callback,
  - completion callback for fixed-length input.
- OTP multi-field linkage support via `FKTextFieldLinkageCoordinator`.

## Supported Format Types
`FKTextFieldFormatType` currently supports:

- `.phoneNumber` -> auto grouped as `138 1234 5678`
- `.idCard` -> supports 15/18 chars, grouped for readability
- `.bankCard` -> grouped by 4 digits
- `.verificationCode(length:allowsAlphabet:)` -> fixed-length code input
- `.password(minLength:maxLength:validatesStrength:)`
- `.amount(maxIntegerDigits:decimalDigits:)` -> thousands separator + decimal precision
- `.email`
- `.numeric`
- `.alphabetic`
- `.alphaNumeric`
- `.custom(regex:maxLength:separator:groupPattern:)`

## Supported Validation Rules
Built-in validation in `FKTextFieldDefaultValidator` includes:

- Phone number length validation (11 digits).
- ID card validation:
  - 15-digit numeric check,
  - 18-digit checksum validation.
- Bank card length range validation (12...24).
- Verification code fixed length validation.
- Password:
  - minimum length validation,
  - optional strength rule (`uppercase + lowercase + digit`).
- Amount format validation based on decimal precision.
- Email regex validation.
- Numeric / alphabetic / alphanumeric character-set validation.
- Custom regex-based validation.

## Requirements
- iOS 13.0+ (component-level API design target)
- Swift 5.9+
- UIKit / Foundation
- No Objective-C dependency
- No third-party dependency

> Note: The current package-level deployment target of this repository may differ from this component-level requirement.

## Installation
Add `FKUIKit` from this repository via Swift Package Manager.

### Xcode
1. Open **File** -> **Add Package Dependencies...**
2. Enter repository URL:
   - `https://github.com/feng-zhang0712/FKKit.git`
3. Select product:
   - `FKUIKit`

### Package.swift
```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.22.0")
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      .product(name: "FKUIKit", package: "FKKit")
    ]
  )
]
```

## Basic Usage

### Create TextField with Code
```swift
import UIKit
import FKUIKit

let field = FKTextField.make(
  formatType: .alphaNumeric,
  placeholder: "Enter content"
)
field.onTextDidChange = { raw, formatted in
  print("raw:", raw, "formatted:", formatted)
}
```

### Create TextField with XIB/Storyboard
1. Drag a `UITextField` into your XIB/Storyboard.
2. Set class name to `FKTextField` in Identity Inspector.
3. Connect IBOutlet and apply rule in code:

```swift
@IBOutlet private weak var otpField: FKTextField!

override func viewDidLoad() {
  super.viewDidLoad()
  otpField.configure(
    FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(
        formatType: .verificationCode(length: 6, allowsAlphabet: false),
        autoDismissKeyboardOnComplete: true
      ),
      placeholder: "6-digit code"
    )
  )
}
```

### Phone Number Format
```swift
let phoneField = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone Number")
```

### ID Card Format
```swift
let idField = FKTextField(
  inputRule: FKTextFieldInputRule(
    formatType: .idCard,
    maxLength: 18
  )
)
```

### Bank Card Format
```swift
let bankField = FKTextField.make(formatType: .bankCard, placeholder: "Bank Card")
```

### Verification Code
```swift
let codeField = FKTextField(
  inputRule: FKTextFieldInputRule(
    formatType: .verificationCode(length: 6, allowsAlphabet: false),
    autoDismissKeyboardOnComplete: true
  )
)
codeField.onInputCompleted = { code in
  print("OTP completed:", code)
}
```

### Password Input
```swift
let passwordField = FKTextField(
  inputRule: FKTextFieldInputRule(
    formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true)
  )
)
passwordField.placeholder = "Password"
```

## Advanced Usage

### Custom Input Limit & Length
```swift
let amountField = FKTextField(
  inputRule: FKTextFieldInputRule(
    formatType: .amount(maxIntegerDigits: 10, decimalDigits: 2),
    maxLength: 13,
    allowsWhitespace: false,
    allowsEmoji: false,
    allowsSpecialCharacters: false,
    debounceInterval: 0.12,
    minimumInputInterval: 0.03
  )
)
```

### Custom Style (Placeholder, Border, Color)
```swift
var style = FKTextFieldStyle.default
style.textColor = .label
style.font = .systemFont(ofSize: 15, weight: .regular)
style.placeholderColor = .tertiaryLabel
style.normal.borderColor = .systemGray4
style.focused.borderColor = .systemBlue
style.error.borderColor = .systemRed
style.normal.cornerRadius = 12
style.normal.backgroundColor = .secondarySystemBackground

let customField = FKTextField(
  configuration: FKTextFieldConfiguration(
    inputRule: FKTextFieldInputRule(formatType: .email),
    style: style,
    attributedPlaceholder: NSAttributedString(
      string: "Email Address",
      attributes: [
        .foregroundColor: UIColor.systemGray,
        .font: UIFont.italicSystemFont(ofSize: 14)
      ]
    )
  )
)
```

### Input Validation & Error Tip
```swift
let emailField = FKTextField.make(formatType: .email, placeholder: "Email")
emailField.onValidationResult = { result in
  print("isValid:", result.isValid, "message:", result.message ?? "none")
}
emailField.onErrorMessage = { message in
  // Bind message to your own error label
  print("error tip:", message ?? "")
}
```

### Left/Right View Customization
```swift
let iconField = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone")
let leftIcon = UIImageView(image: UIImage(systemName: "phone"))
leftIcon.tintColor = .secondaryLabel
leftIcon.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
iconField.leftView = leftIcon
iconField.leftViewMode = .always

let actionButton = UIButton(type: .system)
actionButton.setTitle("Send", for: .normal)
actionButton.frame = CGRect(x: 0, y: 0, width: 52, height: 32)
iconField.rightView = actionButton
iconField.rightViewMode = .always
```

### Secure Text Toggle & Clear Button
```swift
let pwdField = FKTextField(
  inputRule: FKTextFieldInputRule(
    formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true)
  )
)
pwdField.clearButtonMode = .whileEditing  // enabled by default in FKTextField
pwdField.isPasswordVisible = false        // toggle at runtime
```

### Global Style Configuration
```swift
FKTextFieldManager.shared.configureDefaultStyle { style in
  style.normal.cornerRadius = 10
  style.normal.borderColor = .systemGray4
  style.focused.borderColor = .systemBlue
  style.error.borderColor = .systemRed
}

let fieldUsingGlobalStyle = FKTextField(
  inputRule: FKTextFieldInputRule(formatType: .phoneNumber)
)
```

### Custom Regex Format
```swift
let serialField = FKTextField(
  inputRule: FKTextFieldInputRule(
    formatType: .custom(
      regex: "[A-Za-z0-9]",
      maxLength: 12,
      separator: "-",
      groupPattern: [4, 4, 4]
    )
  )
)
```

## API Reference
Core types:
- `FKTextField`
- `FKTextFieldConfiguration`
- `FKTextFieldInputRule`
- `FKTextFieldFormatType`
- `FKTextFieldStyle`
- `FKTextFieldStateStyle`
- `FKTextFieldFormattingResult`
- `FKTextFieldValidationResult`
- `FKTextFieldManager`
- `FKTextFieldLinkageCoordinator`

Main APIs:
- `FKTextField.make(formatType:placeholder:maxLength:)`
- `init(configuration:formatter:validator:)`
- `init(inputRule:)`
- `configure(_:)`
- `updateInputRule(_:)`
- `setError(message:)`
- `clear()`
- `rawText`
- `isPasswordVisible`

Callbacks:
- `onTextDidChange`
- `onFormattedResult`
- `onValidationResult`
- `onErrorMessage`
- `onInputCompleted`

## Best Practices
- Configure `formatType` based on actual business semantics (phone, amount, email, etc.).
- Use `rawText` for API payloads and backend submission.
- Keep UI error rendering in your view layer using `onErrorMessage`.
- Prefer global style defaults for design-system consistency.
- For OTP screens, use `FKTextFieldLinkageCoordinator` to reduce manual focus logic.
- For reused cells, call `clear()` in `prepareForReuse()` to avoid stale state.

## Performance Optimization
- Reuse `FKTextField` instances in list containers when possible.
- Avoid expensive logic inside `onTextDidChange` callbacks.
- Use `debounceInterval` for heavy validation or remote checking.
- Use `minimumInputInterval` to mitigate very high-frequency input events.
- Keep custom left/right views lightweight in scrolling scenarios.

## Notes
- All public APIs are expected to be used on the main thread (`@MainActor`).
- `FKTextField` is a pure UIKit component and does not require subclassing beyond itself.
- The built-in password toggle occupies the right view in password mode. If you set a custom right view, manage visibility behavior according to your product requirement.
- The component is dependency-free and suitable for enterprise and open-source distribution.

## License
`FKTextField` is distributed under the same license as this repository. See [LICENSE](../../../LICENSE).

