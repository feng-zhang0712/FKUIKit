# FKMultiPicker

UIKit bottom sheet with a linked multi-column `UIPickerView`. Data can be an in-memory tree (`FKMultiPickerNode.children`) or supplied lazily via `FKMultiPickerDataProviding` / `FKMultiPickerDataSource`.

**Requirements:** Swift 6 / iOS 15+ (package minimum) · `import UIKit` + `import FKUIKit`

## Source layout

Paths are under `Sources/FKUIKit/Components/MultiPicker/`, mirroring `Badge`: **`Public`** (API you ship against), **`Internal`** (animation, row reuse, data bridge), **`Extension`** (UIKit entry points).

### `Public/`

| File | Role |
|------|------|
| `FKMultiPicker.swift` | Sheet UI, linkage, `show` / `dismiss`, `reloadData`, `present` helpers |
| `FKMultiPickerConfiguration.swift` | Column count, sizes, presentation, `defaultSelectionKeys` |
| `FKMultiPickerStyleModels.swift` | `FKMultiPickerToolbarStyle`, `FKMultiPickerRowStyle`, `FKMultiPickerContainerStyle` |
| `FKMultiPickerPresentationStyle.swift` | `.halfScreen`, `.fullScreen`, `.custom(height:)` |
| `FKMultiPickerNode.swift` | Tree row model (`id`, `title`, `children`) |
| `FKMultiPickerSelection.swift` | `FKMultiPickerSelectionItem`, `FKMultiPickerSelectionResult`, `selectionKeys` |
| `FKMultiPickerProtocols.swift` | `FKMultiPickerDataSource`, `FKMultiPickerDataProviding`, `FKMultiPickerDelegate` |
| `FKMultiPickerTreeDataProvider.swift` | Wraps static roots as `FKMultiPickerDataProviding` |
| `FKMultiPickerSampleAddressData.swift` | `FKMultiPickerSampleAddressData.tree` (demo hierarchy) + `FKMultiPickerSampleAddressDataProvider` |

### `Internal/`

| File | Role |
|------|------|
| `FKMultiPickerAnimator.swift` | Present / dismiss transitions |
| `FKMultiPickerRowFactory.swift` | Reused row `UILabel`s |
| `FKMultiPickerDataProviderBridge.swift` | Adapts `FKMultiPickerDataProviding` → `FKMultiPickerDataSource` |

### `Extension/`

| File | Role |
|------|------|
| `UIViewController+FKMultiPicker.swift` | `fk_presentFKMultiPicker(roots:…)`, `fk_presentFKMultiPicker(dataProvider:…)`, `fk_presentFKMultiPickerSampleAddress(…)` |

## Global defaults

Set once at launch (same idea as `FKBadge.defaultConfiguration`):

```swift
FKMultiPicker.defaultConfiguration.numberOfColumns = 4
FKMultiPicker.defaultConfiguration.toolbarStyle.title = "Choose"
```

## Quick start

**Static tree (embedded `children`):**

```swift
let roots: [FKMultiPickerNode] = [ /* … */ ]
var config = FKMultiPickerConfiguration(numberOfColumns: 3)
FKMultiPicker.present(in: view, roots: roots, configuration: config) { result in
  print(result.joinedTitle)
}
```

**Protocol-driven (`FKMultiPickerDataProviding`):**

```swift
let provider: FKMultiPickerDataProviding = MyProvider()
FKMultiPicker.present(in: view, dataProvider: provider, configuration: config) { result in
  print(result.selectionKeys)
}
```

**Sample four-level address tree (not production geodata):**

```swift
FKMultiPicker.presentSampleAddressPicker(in: view, configuration: config) { result in
  print(result.joinedTitle)
}
// or roots only:
FKMultiPicker.present(in: view, roots: FKMultiPickerSampleAddressData.tree, configuration: config, onConfirmed: nil)
```

**From a view controller:**

```swift
fk_presentFKMultiPicker(roots: nodes, onConfirmed: { _ in })
fk_presentFKMultiPicker(dataProvider: provider, onConfirmed: { _ in })
fk_presentFKMultiPickerSampleAddress(onConfirmed: { _ in })
```

## API summary

| Type / member | Purpose |
|---------------|---------|
| `FKMultiPicker.defaultConfiguration` | Default `FKMultiPickerConfiguration` for inits and `present` |
| `FKMultiPicker(configuration:)` | Build instance; call `updateNodes` or `setDataProvider`, then `show(in:)` |
| `updateNodes(_:)` | Replace level-0 roots (embedded `children` fill deeper columns unless a data source overrides) |
| `setDataProvider(_:)` | Attach `FKMultiPickerDataProviding` and reload |
| `dataSource` / `delegate` | Advanced: custom `FKMultiPickerDataSource`, lifecycle callbacks |
| `reloadData()` | Reload roots from `dataSource`, or keep current roots when using `updateNodes` only |
| `restoreSelection(from:animated:)` | Match a prior `FKMultiPickerSelectionResult` by `id` / `title` |
| `configure(_:)` | Apply new configuration to an existing instance |
| `numberOfColumns` | Visible `UIPickerView` columns (keep as small as practical, e.g. 3–5) |

## Data model notes

- Use stable, unique `id` values per column for `defaultSelectionKeys` and `selectionKeys`.
- `FKMultiPickerDataSource` receives the picker instance (e.g. for context); `FKMultiPickerDataProviding` does not—pick whichever fits your architecture.
- `children(of:atLevel:)` / `multiPicker(_:childrenOf:atLevel:)` use **parent** column index `level` when resolving the next column.

## Example app layout

Under `Examples/.../FKUIKit/MultiPicker/`:

- `FKMultiPickerExampleViewController.swift` — scenarios UI
- `Support/FKMultiPickerDemoSampleData.swift` — static demo trees + global style bootstrap
- `Support/FKMultiPickerDemoCatalogProvider.swift` — demo `FKMultiPickerDataProviding`

## License

Same as the FKKit repository (`LICENSE` at repo root).
