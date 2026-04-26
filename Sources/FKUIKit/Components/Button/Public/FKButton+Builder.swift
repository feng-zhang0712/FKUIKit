import UIKit

public extension FKButton {
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
