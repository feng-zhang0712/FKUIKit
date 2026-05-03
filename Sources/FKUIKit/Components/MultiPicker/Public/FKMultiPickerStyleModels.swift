//
// FKMultiPickerStyleModels.swift
//

import UIKit

/// Toolbar appearance for `FKMultiPicker`.
public struct FKMultiPickerToolbarStyle: Hashable {
  public var title: String
  public var titleColor: UIColor
  public var titleFont: UIFont
  public var cancelTitle: String
  public var cancelTitleColor: UIColor
  public var cancelTitleFont: UIFont
  public var confirmTitle: String
  public var confirmTitleColor: UIColor
  public var confirmTitleFont: UIFont
  public var separatorColor: UIColor
  public var showsSeparator: Bool

  public init(
    title: String = "Please Select",
    titleColor: UIColor = .label,
    titleFont: UIFont = .systemFont(ofSize: 16, weight: .semibold),
    cancelTitle: String = "Cancel",
    cancelTitleColor: UIColor = .secondaryLabel,
    cancelTitleFont: UIFont = .systemFont(ofSize: 15, weight: .regular),
    confirmTitle: String = "Done",
    confirmTitleColor: UIColor = .systemBlue,
    confirmTitleFont: UIFont = .systemFont(ofSize: 15, weight: .semibold),
    separatorColor: UIColor = .separator,
    showsSeparator: Bool = true
  ) {
    self.title = title
    self.titleColor = titleColor
    self.titleFont = titleFont
    self.cancelTitle = cancelTitle
    self.cancelTitleColor = cancelTitleColor
    self.cancelTitleFont = cancelTitleFont
    self.confirmTitle = confirmTitle
    self.confirmTitleColor = confirmTitleColor
    self.confirmTitleFont = confirmTitleFont
    self.separatorColor = separatorColor
    self.showsSeparator = showsSeparator
  }
}

/// Wheel row appearance for `FKMultiPicker`.
public struct FKMultiPickerRowStyle: Hashable {
  public var textColor: UIColor
  public var selectedTextColor: UIColor
  public var font: UIFont
  public var selectedFont: UIFont
  public var rowHeight: CGFloat

  public init(
    textColor: UIColor = .label,
    selectedTextColor: UIColor = .systemBlue,
    font: UIFont = .systemFont(ofSize: 16, weight: .regular),
    selectedFont: UIFont = .systemFont(ofSize: 17, weight: .semibold),
    rowHeight: CGFloat = 40
  ) {
    self.textColor = textColor
    self.selectedTextColor = selectedTextColor
    self.font = font
    self.selectedFont = selectedFont
    self.rowHeight = max(28, rowHeight)
  }
}

/// Bottom sheet container appearance for `FKMultiPicker`.
public struct FKMultiPickerContainerStyle: Hashable {
  public var backgroundColor: UIColor
  public var maskColor: UIColor
  public var cornerRadius: CGFloat
  public var shadowColor: UIColor
  public var shadowOpacity: Float
  public var shadowRadius: CGFloat
  public var shadowOffset: CGSize

  public init(
    backgroundColor: UIColor = .systemBackground,
    maskColor: UIColor = UIColor.black.withAlphaComponent(0.35),
    cornerRadius: CGFloat = 16,
    shadowColor: UIColor = .black,
    shadowOpacity: Float = 0.1,
    shadowRadius: CGFloat = 10,
    shadowOffset: CGSize = CGSize(width: 0, height: -2)
  ) {
    self.backgroundColor = backgroundColor
    self.maskColor = maskColor
    self.cornerRadius = max(0, cornerRadius)
    self.shadowColor = shadowColor
    self.shadowOpacity = max(0, shadowOpacity)
    self.shadowRadius = max(0, shadowRadius)
    self.shadowOffset = shadowOffset
  }
}
