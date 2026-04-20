//
// FKMultiPickerAppearance.swift
//
// Appearance models for FKMultiPicker.
//

import UIKit

/// Visual appearance for picker toolbar.
public struct FKMultiPickerToolbarStyle: Hashable {
  /// Title displayed at the center of the toolbar.
  public var title: String
  /// Text color of the title label.
  public var titleColor: UIColor
  /// Font of the title label.
  public var titleFont: UIFont
  /// Text shown in the cancel button.
  public var cancelTitle: String
  /// Text color of the cancel button.
  public var cancelTitleColor: UIColor
  /// Font used by the cancel button.
  public var cancelTitleFont: UIFont
  /// Text shown in the confirm button.
  public var confirmTitle: String
  /// Text color of the confirm button.
  public var confirmTitleColor: UIColor
  /// Font used by the confirm button.
  public var confirmTitleFont: UIFont
  /// Color of the toolbar bottom separator.
  public var separatorColor: UIColor
  /// Whether the toolbar separator line is visible.
  public var showsSeparator: Bool

  /// Creates a toolbar style object.
  ///
  /// - Parameters:
  ///   - title: Title displayed at the center.
  ///   - titleColor: Title text color.
  ///   - titleFont: Title font.
  ///   - cancelTitle: Cancel button text.
  ///   - cancelTitleColor: Cancel button text color.
  ///   - cancelTitleFont: Cancel button font.
  ///   - confirmTitle: Confirm button text.
  ///   - confirmTitleColor: Confirm button text color.
  ///   - confirmTitleFont: Confirm button font.
  ///   - separatorColor: Toolbar separator color.
  ///   - showsSeparator: Whether separator is displayed.
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

/// Visual appearance for picker rows.
public struct FKMultiPickerRowStyle: Hashable {
  /// Text color for unselected rows.
  public var textColor: UIColor
  /// Text color for the selected row.
  public var selectedTextColor: UIColor
  /// Font for unselected rows.
  public var font: UIFont
  /// Font for the selected row.
  public var selectedFont: UIFont
  /// Height of each picker row.
  public var rowHeight: CGFloat

  /// Creates a row style object.
  ///
  /// - Parameters:
  ///   - textColor: Color for unselected rows.
  ///   - selectedTextColor: Color for selected rows.
  ///   - font: Font for unselected rows.
  ///   - selectedFont: Font for selected rows.
  ///   - rowHeight: Row height. The value is clamped to a minimum safe height.
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

/// Visual appearance for modal container.
public struct FKMultiPickerContainerStyle: Hashable {
  /// Background color of the sheet container.
  public var backgroundColor: UIColor
  /// Color of the fullscreen dimming overlay.
  public var maskColor: UIColor
  /// Corner radius applied to the sheet container.
  public var cornerRadius: CGFloat
  /// Shadow color of the sheet container.
  public var shadowColor: UIColor
  /// Shadow opacity of the sheet container.
  public var shadowOpacity: Float
  /// Shadow blur radius of the sheet container.
  public var shadowRadius: CGFloat
  /// Shadow offset of the sheet container.
  public var shadowOffset: CGSize

  /// Creates a container style object.
  ///
  /// - Parameters:
  ///   - backgroundColor: Sheet background color.
  ///   - maskColor: Dimming overlay color.
  ///   - cornerRadius: Sheet corner radius.
  ///   - shadowColor: Shadow color.
  ///   - shadowOpacity: Shadow opacity.
  ///   - shadowRadius: Shadow blur radius.
  ///   - shadowOffset: Shadow offset.
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
