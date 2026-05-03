# FKTextField

Production-oriented formatted text input on UIKit: filtering, raw vs display values, validation (sync/async), accessories, and global styling. Dependency-free within FKUIKit.

## Requirements

- iOS 15+ (matches FKKitExamples host)
- Swift 6 / `import FKUIKit`

## Source layout

Same layering as **`Badge`**: **`Public`** (exported surface), **`Internal`** (helpers), **`Extension`** (UIKit additions). Root: `Sources/FKUIKit/Components/TextField/`.

`Public/` is split by responsibility:

### `Public/Core/`

| File | Role |
|------|------|
| `FKTextField.swift` | Main control (`UITextField` subclass), pipeline wiring, callbacks |
| `FKTextFieldLinkageCoordinator.swift` | Multi-field focus chaining (OTP-style) |

### `Public/Configuration/`

| File | Role |
|------|------|
| `FKTextFieldConfiguration.swift` | `FKTextFieldConfiguration`, `FKTextFieldInputRule`, layout/accessories/decoration, validation policy, motion, **text input traits** |
| `FKTextFieldManager.swift` | Shared default style & localization |
| `FKTextFieldLocalization.swift` | Strings for accessories & announcements |

### `Public/Types/`

| File | Role |
|------|------|
| `FKTextFieldFormatType.swift` | Built-in format strategies + keyboard hints |
| `FKTextFieldStyle.swift` | Per-state visual tokens |
| `FKTextFieldStatus.swift` | Status enum, validation triggers, message slots |
| `FKTextFieldResults.swift` | Formatter/validator result types |

### `Public/Protocols/`

| File | Role |
|------|------|
| `FKTextFieldProtocols.swift` | `FKTextFieldFormatting`, `FKTextFieldValidating`, `FKTextFieldConfigurable`, **`FKTextInputComponent`** |

### `Public/Pipeline/`

| File | Role |
|------|------|
| `FKTextFieldDefaultFormatter.swift` | Default formatting implementation |
| `FKTextFieldDefaultValidator.swift` | Default sync validation |
| `FKTextFieldAsyncValidator.swift` | Async validation helper types |
| `FKTextFieldCompositeValidator.swift` | Composed validators |

### `Public/Inputs/`

| File | Role |
|------|------|
| `FKCodeTextField.swift` | Slot-based OTP-style control |
| `FKCountTextView.swift` | Multiline counter text view |

### `Public/SwiftUI/`

| File | Role |
|------|------|
| `FKTextFieldRepresentable.swift` | SwiftUI bridge (`FKTextFieldRepresentable`) |

### `Public/Convenience/`

| File | Role |
|------|------|
| `FKTextField+Convenience.swift` | `make` / `makeEmail` / `FKTextFieldBuilder` |

### `Internal/`

| File | Role |
|------|------|
| `FKTextFieldStringParsing.swift` | String sanitizing/grouping helpers for formatters |

### `Extension/`

| File | Role |
|------|------|
| `UIView+FKTextFieldShake.swift` | `UIView.fk_shake(...)` validation feedback |

## API principles

- **English-only public symbols** and doc comments for international consumers.
- **`fk_` prefix** on `FKTextInputComponent` aligns with other FKUIKit extensions and avoids Objective-C selector clashes.
- **Submit-time validation**: call `validateNow()` to run the sync validator immediately regardless of `validationPolicy.trigger` (then refresh UI); optional async validator still runs when sync passes.
- **Password / OTP AutoFill**: defaults applied from `FKTextFieldFormatType`; override via `FKTextFieldConfiguration.textInputTraits` (e.g. `.newPassword`, `passwordRules`, `.username`).

## Quick start

```swift
import UIKit
import FKUIKit

let field = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone")
field.onEditingChanged = { raw, formatted in
  // Persist `raw` for APIs; show `formatted` if needed elsewhere
}
```

Full configuration:

```swift
let cfg = FKTextFieldConfiguration(
  inputRule: FKTextFieldInputRule(formatType: .email),
  placeholder: "you@example.com"
)
let emailField = FKTextField(configuration: cfg)
```

SwiftUI binding:

```swift
FKTextFieldRepresentable(rawText: $raw, configuration: cfg)
```

## Examples

See `Examples/FKKitExamples/.../Examples/FKUIKit/TextField/`:

| Location | Contents |
|----------|----------|
| Root | `FKTextFieldExamplesHubViewController.swift` (sample list), `FKTextFieldExampleSupport.swift` (shared scroll layout) |
| `Scenarios/` | One topic per file (basics, formats, validation, form, OTP, password, keyboard, i18n, theme, IB, SwiftUI, advanced) |

## License

Same as the FKKit repository.
