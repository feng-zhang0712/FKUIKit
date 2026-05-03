# ListKit

**ListKit** groups list-related **state**, **pagination**, and **plugin** helpers used by composite list screens.

## Highlights

- **`FKListStateManager`** / **`FKListState`**: coordinates loading / empty / error / content phases (often paired with **`FKUIKit`** empty states and refresh controls).
- **`FKListPlugin`**: attachable behaviors (e.g. reacting to scroll or lifecycle) without bloating a single view controller.
- **`FKPageManager`** / **`FKPageManagerCore`**: page index and request orchestration for paged APIs.
- **`FKListCapable`**, **`FKListCellConfigurable`**, **`FKListConfiguration`**: shared configuration surfaces for list modules.

Read type-level documentation in the `.swift` files in this directory; behavior is intentionally kept close to the code to avoid drift.
