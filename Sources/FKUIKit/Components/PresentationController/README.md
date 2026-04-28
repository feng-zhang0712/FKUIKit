# FKPresentationController 动画实现分析报告

本文聚焦 `FKPresentationMode` 中 6 种展示模式的动画实现方式，回答以下问题：

- 每种模式出现（present）/消失（dismiss）动画怎么做
- 动画执行时具体修改了哪些视图属性
- 控制这些属性变化的源码位置在哪里

---

## 1. 先看总架构（决定“谁来动”）

### 1.1 模态路径（5 种）

以下 5 种模式都走 UIKit 自定义转场链路：

- `.bottomSheet`
- `.topSheet`
- `.center`
- `.anchor(FKAnchor)`
- `.edge(UIRectEdge)`

调度路径：

- `Core/FKPresentationController.swift`：根据 mode 非 `anchorEmbedded` 时使用 `FKModalPresentationHost`
- `Core/FKPresentationTransitioningDelegate.swift`：返回 `FKPresentationAnimator`
- `Animation/FKPresentationAnimator.swift`：真正执行出现/消失动画（`frame` / `alpha` / `transform`）

### 1.2 嵌入路径（1 种）

`anchorEmbedded(FKEmbeddedAnchorConfiguration)` 不走 `UIPresentationController` 转场，而是走独立宿主：

- `Core/FKPresentationController.swift`：mode 为 `anchorEmbedded` 时使用 `FKEmbeddedAnchorHost`
- `Core/FKEmbeddedAnchorHost.swift`：自建 `UIViewPropertyAnimator`，通过高度折叠与遮罩 alpha 完成出现/消失

---

## 2. 通用动画引擎（模态 5 种共享）

核心文件：`Animation/FKPresentationAnimator.swift`

- 统一状态模型 `State`：`frame`、`alpha`、`transform`
- `apply(state:to:)` 直接落地到 view 属性：
  - `view.frame = ...`
  - `view.alpha = ...`
  - `view.transform = CGAffineTransform(scaleX:y:)`
- 出现动画：先应用 start，再动画到 end
- 消失动画：从 end 反向动画到 start

关键方法位置：

- `interruptibleAnimator(using:)`
- `initialState(for:style:)`
- `finalState(for:style:)`
- `initialFrame(for:)`（不同 mode 的位移起点）
- `apply(state:to:)`

---

## 3. 六种模式逐项分析

## 3.1 `.bottomSheet`

### 出现动画

- 方式：从屏幕下方滑入（sheet-like）
- 初始 frame：`baseFrame.offsetBy(dx: 0, dy: baseFrame.height)`
- 终点 frame：`baseFrame`

### 消失动画

- 方式：向下滑出到屏幕外
- 反向回到上述初始 frame

### 动画期间被修改的属性

- 主要：`frame.origin.y`（通过整体 `frame` 改变）
- 常规非 Reduce Motion：`alpha = 1`、`transform = identity`（几乎不变）
- Reduce Motion 时：会启用淡入/淡出（`alpha` 变化）

### 代码位置

- 位移起点：`Animation/FKPresentationAnimator.swift` 的 `initialFrame(for:)` 中 `case .bottomSheet`
- 属性应用：`Animation/FKPresentationAnimator.swift` 的 `apply(state:to:)`
- 样式族解析（sheet-like）：`Animation/FKPresentationAnimator.swift` 的 `FKAnimationStyleResolver.family(for:)` 与 `resolveSheetLikeStyle(...)`

### 交互拖拽补充（非纯转场，但用户可感知动画）

- 在 detent 区间内，优先改 `wrapperView.frame.size.height` 并保持底边吸附
- 到最低 detent 后下拉，改 `wrapperView.frame.origin.y` 形成“预 dismiss”
- backdrop 联动：`backdropView.alpha` 随进度变化

代码位置：

- `Core/FKContainerPresentationController.swift` 的 `handleSheetPan(_:in:)`
- `Core/FKContainerPresentationController.swift` 的 `updateBackdropForCurrentState()`

---

## 3.2 `.topSheet`

### 出现动画

- 方式：从屏幕上方滑入
- 初始 frame：`baseFrame.offsetBy(dx: 0, dy: -baseFrame.height)`
- 终点 frame：`baseFrame`

### 消失动画

- 方式：向上滑出

### 动画期间被修改的属性

- 主要：`frame.origin.y`（通过 `frame`）
- 常规：`alpha/transform` 基本不变（sheet-like）
- Reduce Motion：允许 `alpha` 变化

### 代码位置

- `Animation/FKPresentationAnimator.swift` 的 `initialFrame(for:)` 中 `case .topSheet`
- `Animation/FKPresentationAnimator.swift` 的 `apply(state:to:)`
- `Animation/FKPresentationAnimator.swift` 的 `resolveSheetLikeStyle(...)`

### 交互拖拽补充

- TopSheet 交互主要通过改 `wrapperView.frame.size.height`（顶部锚定）实现
- 达到阈值后可触发交互 dismiss

代码位置：

- `Core/FKContainerPresentationController.swift` 的 `handleSheetPan(_:in:)`（`case .topSheet`）

---

## 3.3 `.center`

### 出现动画

- 方式：alert-like（中心淡入 + 轻微缩放）
- 初始 frame：`baseFrame`（不做位移）
- 初始 transform：`scale(0.95)`（默认 system-like 分支）
- 初始 alpha：`0`
- 终点：`transform = identity`、`alpha = 1`

### 消失动画

- 方式：轻微缩小 + 淡出
- 终点 transform：`scale(0.97)`
- 终点 alpha：`0`

### 动画期间被修改的属性

- `alpha`（显式淡入淡出）
- `transform`（缩放）
- `frame` 理论上也经 `apply(state:)` 写入，但通常起终点一致

### 代码位置

- 家族判定：`Animation/FKPresentationAnimator.swift` 的 `FKAnimationStyleResolver.family(for:)`
- Center 样式：`Animation/FKPresentationAnimator.swift` 的 `resolveAlertLikeCenterStyle(...)`
- 状态应用：`Animation/FKPresentationAnimator.swift` 的 `apply(state:to:)`

### 交互拖拽补充

- Center 的手势 dismiss 使用进度驱动转场控制器，不直接在手势回调里改 frame

代码位置：

- `Core/FKContainerPresentationController.swift` 的 `handleCenterPan(_:in:)`
- `Interaction/FKPresentationDismissInteractionController.swift`

---

## 3.4 `.anchor(FKAnchor)`（模态锚点）

### 出现动画

- 方式：锚点附近短距离位移进入（非整屏滑入）
- 位移幅度固定 `delta = 12`
- 根据 anchor 方向决定起点：
  - `.up`：从下方一点点进入（`dy: +12`）
  - `.down`：从上方一点点进入（`dy: -12`）
  - `.auto`：根据 `anchor.edge` 推断方向

### 消失动画

- 方式：反向退回上述偏移起点

### 动画期间被修改的属性

- 主要：`frame.origin.y`（通过小位移）
- 常规 sheet-like：`alpha/transform` 基本不变
- Reduce Motion：可能启用 alpha 变化

### 代码位置

- 位移策略：`Animation/FKPresentationAnimator.swift` 的 `initialFrame(for:)` 中 `case let .anchor(anchor)`
- 锚点 frame 计算：`Core/FKPresentationAnchorLayout.swift` 的 `anchoredFrame(...)`
- 属性应用：`Animation/FKPresentationAnimator.swift` 的 `apply(state:to:)`

---

## 3.5 `.anchorEmbedded(FKEmbeddedAnchorConfiguration)`（嵌入锚点）

> 注意：这是唯一不走 `FKPresentationAnimator` 的模式。

### 出现动画

- 方式：保持弹窗高度不变，通过 `y` 轴位移进入
- 初始 frame：`offsetFrameByHeight(...)`（`origin.y` 偏移量等于弹窗高度）
- 终点 frame：`resolved.targetFrame`
- 同时遮罩从 0 到 1：`animateMaskAlpha(0 -> 1)`

### 消失动画

- 方式：保持弹窗高度不变，通过 `y` 轴位移离场（位移量同样等于弹窗高度）
- 同时遮罩从 1 到 0：`animateMaskAlpha(1 -> 0)`

### 动画期间被修改的属性

- `wrapperView.frame.origin.y`（通过整帧 `offsetBy`，偏移量 = 弹窗高度）
- `maskView` 相关 alpha（通过 `animateMaskAlpha(...)`）
- `wrapperView.alpha` 在 present 前被置为 1

### 代码位置

- 动画入口：`Core/FKEmbeddedAnchorHost.swift` 的 `makeAnimator(isPresentation:animated:)`
- 位移 frame 计算：`Core/FKEmbeddedAnchorHost.swift` 的 `offsetFrameByHeight(from:direction:)`
- 锚点几何解析：`Core/FKEmbeddedAnchorHost.swift` 的 `resolveLayout(in:)` + `Core/FKPresentationAnchorLayout.swift` 的 `anchoredFrame(...)`

---

## 3.6 `.edge(UIRectEdge)`

### 出现动画

- 方式：按指定边缘滑入
- 初始 frame：
  - `.left`：`dx: -width`
  - `.right`：`dx: +width`
  - `.top`：`dy: -height`
  - 其他（通常 bottom）：`dy: +height`

### 消失动画

- 方式：沿相反方向滑出到对应边缘外

### 动画期间被修改的属性

- 主要：`frame.origin.x` 或 `frame.origin.y`
- 常规 sheet-like：`alpha/transform` 基本不变
- Reduce Motion：可能有 alpha 变化

### 代码位置

- 位移起点：`Animation/FKPresentationAnimator.swift` 的 `initialFrame(for:)` 中 `case let .edge(edge)`
- 属性应用：`Animation/FKPresentationAnimator.swift` 的 `apply(state:to:)`

---

## 4. 汇总：每种模式“真正动了什么”

- `bottomSheet`：主改 `frame.origin.y`（交互时还会改 `frame.size.height`）
- `topSheet`：主改 `frame.origin.y`（交互时重点改 `frame.size.height`）
- `center`：主改 `alpha + transform(scale)`，frame 基本稳定
- `anchor`：主改 `frame.origin.y`（锚点附近 12pt 微位移）
- `anchorEmbedded`：主改 `frame.size.height`（0 到目标）+ 遮罩 alpha
- `edge`：主改 `frame.origin.x/y`（按边缘方向平移）

通用属性写入口（模态 5 种）：

- `Animation/FKPresentationAnimator.swift` 的 `apply(state:to:)`

嵌入模式属性写入口：

- `Core/FKEmbeddedAnchorHost.swift` 的 `makeAnimator(isPresentation:animated:)` 内对 `hostVC.wrapperView.frame` 和 `hostVC.animateMaskAlpha(...)` 的调用

