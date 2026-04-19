//
//  FKButton+Chaining.swift
//
//  链式配置：`with…` 与直接设置同名公开属性等价，返回 `Self`，便于在 `FKButton()` 或属性初始化里连续书写。
//  Groups: tap/hit area, disabled dimming, loading, content & axis, appearances, long-press callbacks.
//

import UIKit

// MARK: - Chaining API

public extension FKButton {

  // MARK: Tap & hit testing

  @discardableResult
  func withMinimumTapInterval(_ value: TimeInterval) -> Self {
    minimumTapInterval = value
    return self
  }

  @discardableResult
  func withHitTestEdgeInsets(_ value: UIEdgeInsets) -> Self {
    hitTestEdgeInsets = value
    return self
  }

  // MARK: Disabled appearance

  @discardableResult
  func withAutomaticallyDimsWhenDisabled(_ value: Bool) -> Self {
    automaticallyDimsWhenDisabled = value
    return self
  }

  @discardableResult
  func withDisabledDimmingAlpha(_ value: CGFloat) -> Self {
    disabledDimmingAlpha = value
    return self
  }

  // MARK: Loading

  @discardableResult
  func withLoadingPresentationStyle(_ value: LoadingPresentationStyle) -> Self {
    loadingPresentationStyle = value
    return self
  }

  @discardableResult
  func withLoadingActivityIndicatorColor(_ value: UIColor?) -> Self {
    loadingActivityIndicatorColor = value
    return self
  }

  // MARK: Content & layout

  @discardableResult
  func withContent(_ value: Content) -> Self {
    content = value
    return self
  }

  @discardableResult
  func withContentHorizontalAlignment(_ value: UIControl.ContentHorizontalAlignment) -> Self {
    contentHorizontalAlignment = value
    return self
  }

  @discardableResult
  func withContentVerticalAlignment(_ value: UIControl.ContentVerticalAlignment) -> Self {
    contentVerticalAlignment = value
    return self
  }

  @discardableResult
  func withAxis(_ value: Axis) -> Self {
    axis = value
    return self
  }

  @discardableResult
  func withAppearances(_ value: StateAppearances) -> Self {
    setAppearances(value)
    return self
  }

  // MARK: Long press

  @discardableResult
  func withLongPressMinimumDuration(_ value: TimeInterval) -> Self {
    longPressMinimumDuration = value
    return self
  }

  @discardableResult
  func withLongPressRepeatTickInterval(_ value: TimeInterval) -> Self {
    longPressRepeatTickInterval = value
    return self
  }

  @discardableResult
  func withOnLongPressBegan(_ handler: (() -> Void)?) -> Self {
    onLongPressBegan = handler
    return self
  }

  @discardableResult
  func withOnLongPressEnded(_ handler: (() -> Void)?) -> Self {
    onLongPressEnded = handler
    return self
  }

  @discardableResult
  func withOnLongPressRepeatTick(_ handler: (() -> Void)?) -> Self {
    onLongPressRepeatTick = handler
    return self
  }
}
