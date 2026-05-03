# FKButton

UIKit control for production buttons: multi-state title and subtitle, optional leading/center/trailing images, custom embedded views, gradients, loading states, throttled primary actions, and optional haptics / sound / pointer feedback.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

Same layering as **`Badge`**: **`Public`** (types you configure from app code), **`Internal`** (layout helpers), **`Extension`** (builder chain and Interface Builder). Paths live under `Sources/FKUIKit/Components/Button/`.

### `Public/`

| File | Role |
|------|------|
| `FKButton/` | Implementation slices for `FKButton` (see table below) |
| `FKButtonAliases.swift` | `FKButton.Content`, `FKButton.Appearance`, … short typealiases |

#### `Public/FKButton/` (`FKButton` control)

| File | Role |
|------|------|
| `FKButton.swift` | Nested types, stored properties, inits, `deinit`, `isEnabled` / `isSelected` / `isHighlighted` |
| `FKButton+Setup.swift` | `commonInit()`, `applyFactoryDefaultsFromGlobalStyle()` |
| `FKButton+PublicAPI.swift` | `setModel`, labels, images, appearance, batch updates |
| `FKButton+Layout.swift` | Content alignment overrides, `intrinsicContentSize`, `layoutSubviews`, hit testing hook |
| `FKButton+ControlDispatch.swift` | `sendActions` / `sendAction`, primary-action throttling |
| `FKButton+Loading.swift` | `setLoading`, `performWhileLoading`, loading overlay views |
| `FKButton+InteractionGestures.swift` | Hit bounds helpers, long-press handler |
| `FKButton+LayoutEngine.swift` | Stack alignment, refresh pipeline, title/image/custom host lifecycle |
| `FKButton+StackContent.swift` | Arranged subview composition for `content.kind` |
| `FKButton+AppearanceRendering.swift` | Background, border, shadow, corner metrics, `activeImageElements` |
| `FKButton+ContentRendering.swift` | Text/image resolution, `UILabel` / `UIImageView` application, padded symbols |
| `FKButton+Accessibility.swift` | VoiceOver traits and default label/value/hint |
| `FKButton+Feedback.swift` | Haptics/sound dispatch, pointer hover sync |
| `FKButton+PointerInteraction.swift` | `UIPointerInteractionDelegate` |
| `FKButton+InterfaceBuilderHooks.swift` | `prepareForInterfaceBuilder()` |

Other configuration types remain directly under `Public/`:

| File | Role |
|------|------|
| `FKButtonContentConfiguration.swift` | Content kind (text / image / text+image / custom) |
| `FKButtonElementConfiguration.swift` | `FKButtonLabelConfiguration`, `FKButtonImageConfiguration`, `FKButtonCustomContentConfiguration` |
| `FKButtonStateModel.swift` | Bundle model for `setModel(_:for:)` |
| `FKButtonAppearance.swift` | `FKButtonAppearance`, corners, border, shadow, gradient, `FKButtonStateAppearances` |
| `FKButtonLoadingPresentation.swift` | `FKButtonLoadingPresentation` + replacement options |
| `FKButtonGlobalStyle.swift` | Process-wide defaults for new instances |
| `FKButtonAccessibilityConfiguration.swift` | Optional VoiceOver label/value/hint providers |
| `FKButtonFeedbackConfigurations.swift` | Haptics, sound, pointer configuration structs |

### `Internal/`

| File | Role |
|------|------|
| `FKButtonCustomContentHostView.swift` | Intrinsic sizing host for `.custom` content inside the stack |

### `Extension/`

| File | Role |
|------|------|
| `FKButton+Builder.swift` | `withMinimumTapInterval`, `withContent`, … fluent API |
| `FKButton+InterfaceBuilder.swift` | `fk_*` `@IBInspectable` properties |

## Naming convention

- **Module-level types** use the `FKButton…` prefix (`FKButtonAppearance`, `FKButtonLabelConfiguration`, …). These names are stable in docs and binary-compatible evolution.
- **Scoped aliases** under `FKButton` (`FKButton.Appearance`, `FKButton.LabelAttributes`, …) are ergonomic shorthand; use either style consistently.

## Quick start

```swift
import UIKit
import FKUIKit

let button = FKButton()
button.content = .textOnly
button.setTitle(.init(text: "Continue", font: .boldSystemFont(ofSize: 17), color: .white), for: .normal)
button.setAppearances(.init(normal: .filled(backgroundColor: .systemBlue, cornerStyle: .init(corner: .fixed(12)))))
button.addAction(UIAction { _ in … }, for: .touchUpInside)
```

Text + leading symbol:

```swift
button.content = .textAndImage(.leading)
button.setLeadingImage(.init(systemName: "paperplane.fill", tintColor: .white), slot: .leading, for: .normal)
```

Use `setLeadingImage` / `setTrailingImage` / `setCenterImage` convenience APIs instead of `setImage(_:slot:for:)` when the slot is fixed.

## State resolution

- Register appearance and content per **exact** `UIControl.State` bit pattern.
- Default resolution order when `stateResolutionProvider` is `nil`: disabled (with selected variant if needed) → highlighted+selected → highlighted → selected → normal.
- **`setModel(nil, for: state)`** removes appearance, title, subtitle, all image slots, and custom content for that **exact** state key so fallbacks apply again.
- Non-`nil` **`setModel`** is **partial**: omitted fields (e.g. `images == nil`) do not clear existing slot registrations.

## Interaction notes

- **Throttling** applies only to primary actions (UIKit may call `sendAction` directly; `FKButton` intercepts that path).
- **Loading** forces interaction off and suppresses primary actions until cleared.
- **Long press** uses a gesture recognizer with `cancelsTouchesInView = false` so normal taps still work.
- **Pointer** interaction is attached only on iPad / Mac idiom when enabled; call sites should not rely on hover where pointer APIs are unavailable.

## Global defaults

Set once at launch if desired:

```swift
FKButton.GlobalStyle.minimumTapInterval = 0.35
FKButton.GlobalStyle.defaultAppearances = …
FKButton.GlobalStyle.applyPerNewButton = { button in … }
```

Avoid relying on mutable global state across unrelated features without restoring previous values (see sample app “GlobalStyle snapshot”).

## Examples

Under `Examples/FKKitExamples/.../Examples/FKUIKit/Button/`:

| Location | Contents |
|----------|----------|
| Root | `FKButtonExamplesHubViewController.swift`, `FKButtonExampleSupport.swift` (layout helpers + shared scroll shell) |
| `Scenarios/` | One view controller per topic (basics, layout, interaction, appearance, loading, advanced) |

## License

Same as the FKKit repository.
