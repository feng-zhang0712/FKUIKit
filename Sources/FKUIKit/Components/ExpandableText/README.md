# FKExpandableText

UIKit-first expandable attributed text: collapse long copy to a line budget, append localized actions, and update layout synchronously. A thin SwiftUI wrapper reuses the same `UITextView` engine.

## Requirements

- Swift 6, iOS 15+
- `import FKUIKit`

## Source layout

Aligned with `Badge`, `Divider`, and other FKUIKit modules:

| Layer | Files |
|-------|--------|
| **`Public/`** | `FKExpandableText` (namespace + `attach`), `FKExpandableTextConfiguration`, `FKExpandableTextState`, `FKExpandableTextLabelController`, `FKExpandableTextLinkedTextViewController`, `FKExpandableTextView` (SwiftUI) |
| **`Internal/`** | `FKExpandableTextTextBuilder`, `FKExpandableTextLayoutCache`, `FKExpandableTextMeasurementWidth` |
| **`Extension/`** | `UILabel+FKExpandableText`, `UITextView+FKExpandableText` |

## Concepts

- **Source text** — You always pass the *full* `NSAttributedString`. The library derives collapsed/expanded display strings.
- **Defaults** — ``FKExpandableText/defaultConfiguration`` mirrors `FKBadge.defaultConfiguration`: assign once at launch, or pass an explicit `FKExpandableTextConfiguration` per call.
- **`UILabel`** — Taps are hit-tested with Text Kit so `interactionMode == .buttonOnly` stays precise.
- **`UITextView`** — Expand/collapse uses a synthetic `fkexpand://` link on the action substring; your real `http(s):` links call ``FKExpandableTextLinkedTextViewController/onLinkTapped`` and still reach any existing `UITextViewDelegate`.

## Quick start (UIKit)

```swift
import UIKit
import FKUIKit

label.fk_setExpandableText(
  NSAttributedString(string: longCopy, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]),
  onExpansionChange: { state in
    // analytics, reload rows, etc.
  }
)
```

```swift
FKExpandableText.attach(
  to: textView,
  attributedText: richAttributedString,
  onExpansionChange: { _ in }
)?.onLinkTapped = { url in
  UIApplication.shared.open(url)
}
```

## Quick start (SwiftUI)

```swift
import SwiftUI
import FKUIKit

FKExpandableTextView(
  attributedText: model.body,
  configuration: FKExpandableTextConfiguration(collapseRule: .lines(3)),
  isExpanded: $model.isExpanded,
  onExpansionChange: { _ in },
  onLinkTapped: { url in /* open */ }
)
```

## Global defaults

```swift
FKExpandableText.defaultConfiguration.expandActionText = NSAttributedString(
  string: NSLocalizedString("read_more", comment: ""),
  attributes: [.foregroundColor: UIColor.link]
)
```

## API summary

### `FKExpandableText`

- `defaultConfiguration` — shared baseline `FKExpandableTextConfiguration`.
- `attach(to: UILabel, attributedText:configuration:onExpansionChange:)` → `FKExpandableTextLabelController`
- `attach(to: UITextView, attributedText:configuration:onExpansionChange:)` → `FKExpandableTextLinkedTextViewController`

### `UILabel` / `UITextView`

- `fk_expandableText` — lazily created controller (retained via associated object).
- `fk_setExpandableText(_:configuration:onExpansionChange:)` — attributed overload.
- `fk_setExpandableText(_:attributes:configuration:onExpansionChange:)` — plain `String` overload.
- `UITextView` adds `onLinkTapped` on the `String` overload as well.

### Controllers

- `setText(_:)`, `setConfiguration(_:)`, `toggle()`, `setExpanded(_:animated:)`, `refreshLayout()`, read-only `state`, `onExpansionChange`.
- `FKExpandableTextLinkedTextViewController` also exposes `onLinkTapped`.

### `FKExpandableTextConfiguration`

- `collapseRule`: `.lines(n)` or `.noBodyTruncation`
- `buttonPlacement`: `.inlineTail` (body + token + action within the line budget) or `.trailingBottom` (body + token within `n - 1` lines, then the action on the following line so overall height stays close to `n` lines).
- `interactionMode`: `.buttonOnly` or `.fullTextArea`
- `oneWayExpand`, `truncationToken`, `expandActionText`, `collapseActionText`, `accessibility`

## Layout notes

- Truncation uses the label or text view width. Before the first layout pass, width is inferred from `preferredMaxLayoutWidth` (labels) and then the nearest ancestor with a resolved width, instead of assuming the full screen width (which could hide “Read more” on narrow cards).
- `UILabel` / `UITextView` hosts use **word wrapping** for line-budget math (UIKit’s default tail truncation skews Text Kit line counts).
- After the host gets a real `bounds.width`, the controller schedules a one-shot `refreshLayout()` so line-based collapse picks up the correct width.
- If you assign text before the view is in a hierarchy, `setText` schedules an extra `refreshLayout()` on the next run-loop turn once a superview exists.
- You can still call ``FKExpandableTextLabelController/refreshLayout()`` manually after width-driven changes.
- Prefer debouncing rapid model updates before calling `fk_setExpandableText` in high-frequency feeds.

## Examples

See `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ExpandableText/` (`FKExpandableTextExampleSupport.swift`, `Examples/` per-topic view controllers, hub controller).
