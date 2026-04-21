# FKSticky

`FKSticky` is a pure UIKit/Foundation sticky component for iOS 13+.

## Features

- Generic `UIView` sticky support
- `UITableView` section/header sticky support
- `UICollectionView` section/header sticky support
- Multi-target chained sticky transitions
- Dynamic enable/disable and target-level toggles
- Safe-area/navigation-bar friendly offsets
- Runtime callbacks for sticky lifecycle and scrolling
- Rotation/layout refresh friendly APIs

## Quick Start

```swift
let headerView = UIView()
let scrollView = UIScrollView()

var config = FKStickyConfiguration.default
config.additionalTopInset = 8
scrollView.fk_stickyEngine.apply(configuration: config)

let target = FKStickyTarget(
  id: "header",
  viewProvider: { [weak headerView] in headerView },
  threshold: headerView.frame.minY,
  onStyleChanged: { style, view in
    view.backgroundColor = (style == .sticky) ? .systemBlue : .systemGray5
  }
)
scrollView.fk_stickyEngine.addTarget(target)
```

```swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
  scrollView.fk_handleStickyScroll()
}
```

## Design Notes

- Protocol-oriented API via `FKStickyControllable`
- Lightweight engine per scroll view
- Main-thread-only state transitions for UIKit safety
- Transform-based updates to reduce layout churn
