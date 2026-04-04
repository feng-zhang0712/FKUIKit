# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划中
- 单元测试 target 与 `Tests/` 目录
- 可选：`Examples` 示例 App（本地依赖本 Package）

## [0.1.0] - 2026-04-04

### Added
- 多 Product 布局：`FKUIKitCore`、`FKButton`、`FKBar`、`FKPresentation`、`FKPopover`
- `Package.swift`：`platforms: [.iOS(.v15)]`、`swiftLanguageModes: [.v6]`
- `README.md`、`LICENSE`（MIT）、`CHANGELOG.md`、扩充后的 `.gitignore`

### Changed（为 SPM / Swift 6 可编译）
- 各配置类型上 `static let default` 使用 `nonisolated(unsafe)`，避免全局 `default` 的并发检查报错
- `FKBarConfigurationAssociatedKeys` 使用 `nonisolated(unsafe)` 关联对象 key
- `FKBar` / `FKPopover` 等补充 `import FKUIKitCore`、`FKButton`、`FKPresentation`、`FKBar` 等模块引用
- `FKPresentation` 标为 `@MainActor`；`FKBarDelegate`、`FKPresentationDelegate`、`FKPresentationDataSource` 标为 `@MainActor`
- `FKBar.Item.FKButtonSpec.apply(to:)` 标为 `@MainActor`
- `FKPopover.PresentationDismissReason` 遵循 `Sendable`

<!-- 发布到远程后，可将下方链接替换为实际仓库 URL -->
[Unreleased]: #
[0.1.0]: #
