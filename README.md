# FKUIKit

iOS 组件库：`FKButton`、`FKBar`、`FKPresentation`、`FKPopover` 及共享模块 `FKUIKitCore`。与系统 `UIPopoverPresentationController` 无绑定关系；`FKPopover` 为 `FKBar` + 锚点浮层的组合封装。

## 要求

| 项目 | 版本 |
|------|------|
| iOS | 15.0+ |
| Swift | 6.0+（`Package.swift` 使用 `swiftLanguageModes: [.v6]`；配置类型上的 `static let default` 使用 `nonisolated(unsafe)` 以满足默认并发检查） |
| Xcode | 建议使用当前稳定版（需在 Xcode 中针对 **iOS** 解析/编译；命令行 `swift build` 默认主机平台无 `UIKit`） |

## 通过 Swift Package Manager 集成

1. Xcode：**File → Add Package Dependencies…**
2. 填入本仓库 URL，选择版本规则（如 **Up to Next Major**）。
3. 在 **Add to Target** 中勾选需要的 **Product**（见下表）。

### Products 与 `import`

按需只引入用到的模块，减少编译与符号暴露面：

| Product | `import` | 说明 |
|---------|----------|------|
| FKUIKitCore | `FKUIKitCore` | 公共类型别名、`EdgeStripShadowPath` 等 |
| FKButton | `FKButton` | 按钮控件 |
| FKBar | `FKBar` | 依赖 `FKButton`、`FKUIKitCore` |
| FKPresentation | `FKPresentation` | 锚点浮层 |
| FKPopover | `FKPopover` | 依赖 `FKBar`、`FKPresentation`、`FKUIKitCore` |

依赖关系（无环）：

```text
FKUIKitCore
FKButton            → FKUIKitCore
FKBar               → FKButton, FKUIKitCore
FKPresentation      → FKUIKitCore
FKPopover           → FKBar, FKPresentation, FKUIKitCore
```

### 本地路径依赖（开发）

在 App 工程的 Package 依赖中选择 **Add Local…**，指向本仓库根目录（含 `Package.swift` 的文件夹）。

## 最小示例

```swift
import UIKit
import FKButton

let button = FKButton()
button.setTitle(.init(text: "OK"), for: .normal)
```

组合条与浮层时：

```swift
import FKPopover

let popover = FKPopover(frame: .zero)
popover.reloadBarItems([/* FKBar.Item */])
```

## 构建说明

- 在 **Xcode** 中打开本仓库根目录的 Package，Scheme 选择任一库 target 或 **FKUIKit-Package**，Destination 选 **iOS 设备 / 模拟器** 即可编译。
- 若在终端使用 `swift build`，需能解析到 **iOS SDK**（通常仍以 Xcode 构建为准）。

## 版本与变更

语义化版本见仓库 **Tags**；变更记录见 [CHANGELOG.md](CHANGELOG.md)。

## Swift 6 与并发

- 库以 **Swift 6** 语言模式构建；部分 UI 配置上的 `static let default` 使用 `nonisolated(unsafe)`（值为不可变默认配置，首次访问在主线程/UI 上下文即可）。
- `FKPresentation` 为 **`@MainActor`**；`FKBarDelegate`、`FKPresentationDelegate`、`FKPresentationDataSource` 约定在 **主线程** 回调（与 UIKit 一致）。实现这些协议的类型无需额外标注，由编译器按协议隔离域处理。

若你从其它工程 **再次覆盖** `Sources/`，请核对是否仍需上述与 SPM 相关的修改，或改为在本仓库直接维护。

## 许可证

[MIT License](LICENSE)
