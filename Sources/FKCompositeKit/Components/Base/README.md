# Base (`FKBase*`)

This folder contains **reusable base classes** for large apps:

- **`FKBaseViewController`**: common lifecycle hooks, keyboard/tap-to-dismiss patterns, navigation bar helpers, and lightweight diagnostics hooks.
- **`FKBaseTableViewCell`** / **`FKBaseCollectionViewCell`**: standardized container layout, style entry points, and `reuseIdentifier` defaults.

These types are **UIKit-first** and are meant to be **subclassed** rather than used as black-box components. See inline comments on each class for override points and threading expectations (**`@MainActor`**).
