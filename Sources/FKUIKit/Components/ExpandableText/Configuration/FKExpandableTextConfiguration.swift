//
// FKExpandableTextConfiguration.swift
//
// Configuration models for FKExpandableText.
//

import UIKit

/// Defines where the expand/collapse button should be displayed.
public enum FKExpandableTextButtonPosition: Hashable {
  /// Places the button inside the label area at bottom trailing.
  case tailFollow
  /// Places the button below text and aligns it to trailing edge.
  case bottomTrailing
}

/// Option set that controls how expand/collapse can be triggered.
public struct FKExpandableTextTriggerMode: OptionSet, Hashable, Sendable {
  /// Bitmask raw value backing the trigger option set.
  public let rawValue: Int

  /// Creates a trigger mode from raw bitmask value.
  ///
  /// - Parameter rawValue: Raw option-set bitmask.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Allows tap on button to toggle state.
  public static let button = FKExpandableTextTriggerMode(rawValue: 1 << 0)
  /// Allows tap on text label to toggle state.
  public static let text = FKExpandableTextTriggerMode(rawValue: 1 << 1)
  /// Allows both button and text as trigger source.
  public static let all: FKExpandableTextTriggerMode = [.button, .text]
}

/// Text presentation style for expandable content.
public struct FKExpandableTextTextStyle {
  /// Primary font used to render the text body.
  public var font: UIFont
  /// Primary text color used to render the text body.
  public var color: UIColor
  /// Text alignment applied to all lines.
  public var alignment: NSTextAlignment
  /// Extra line spacing used in paragraph style. Minimum is `0`.
  public var lineSpacing: CGFloat
  /// Character spacing applied via `.kern`.
  public var kern: CGFloat
  /// Truncation mode used while collapsed.
  public var lineBreakMode: NSLineBreakMode

  /// Creates text style for expandable text body.
  ///
  /// - Parameters:
  ///   - font: Text font. Default is `.systemFont(ofSize: 15)`.
  ///   - color: Text color. Default is `.label`.
  ///   - alignment: Paragraph alignment. Default is `.left`.
  ///   - lineSpacing: Extra spacing between lines. Values below `0` are clamped.
  ///   - kern: Character spacing.
  ///   - lineBreakMode: Truncation mode used in collapsed state.
  public init(
    font: UIFont = .systemFont(ofSize: 15),
    color: UIColor = .label,
    alignment: NSTextAlignment = .left,
    lineSpacing: CGFloat = 4,
    kern: CGFloat = 0,
    lineBreakMode: NSLineBreakMode = .byTruncatingTail
  ) {
    self.font = font
    self.color = color
    self.alignment = alignment
    self.lineSpacing = max(0, lineSpacing)
    self.kern = kern
    self.lineBreakMode = lineBreakMode
  }
}

/// Expand/collapse button visual style.
public struct FKExpandableTextButtonStyle {
  /// Button title shown while text is collapsed.
  public var expandTitle: String
  /// Button title shown while text is expanded.
  public var collapseTitle: String
  /// Title color for normal state.
  public var titleColor: UIColor
  /// Title color for highlighted state.
  public var highlightedTitleColor: UIColor
  /// Font used by button title.
  public var font: UIFont
  /// Optional icon displayed near title.
  public var image: UIImage?
  /// Optional tint color for icon. Falls back to `titleColor` when `nil`.
  public var imageTintColor: UIColor?
  /// Spacing between icon and title. Minimum is `0`.
  public var imageTitleSpacing: CGFloat
  /// Content insets applied to button tap area and layout.
  public var contentInsets: UIEdgeInsets

  /// Creates visual style for expand/collapse button.
  ///
  /// - Parameters:
  ///   - expandTitle: Title for collapsed state.
  ///   - collapseTitle: Title for expanded state.
  ///   - titleColor: Normal title color.
  ///   - highlightedTitleColor: Highlighted title color.
  ///   - font: Title font.
  ///   - image: Optional icon.
  ///   - imageTintColor: Optional icon tint color.
  ///   - imageTitleSpacing: Spacing between icon and title. Values below `0` are clamped.
  ///   - contentInsets: Button content insets.
  public init(
    expandTitle: String = "Read more",
    collapseTitle: String = "Collapse",
    titleColor: UIColor = .systemBlue,
    highlightedTitleColor: UIColor = .systemGray,
    font: UIFont = .systemFont(ofSize: 14, weight: .semibold),
    image: UIImage? = nil,
    imageTintColor: UIColor? = nil,
    imageTitleSpacing: CGFloat = 4,
    contentInsets: UIEdgeInsets = .zero
  ) {
    self.expandTitle = expandTitle
    self.collapseTitle = collapseTitle
    self.titleColor = titleColor
    self.highlightedTitleColor = highlightedTitleColor
    self.font = font
    self.image = image
    self.imageTintColor = imageTintColor
    self.imageTitleSpacing = max(0, imageTitleSpacing)
    self.contentInsets = contentInsets
  }
}

/// Layout and animation style for the component.
public struct FKExpandableTextLayoutStyle {
  /// Inner insets applied around text and button content.
  public var contentInsets: UIEdgeInsets
  /// Vertical spacing between text area and button in `.bottomTrailing` mode.
  public var textButtonSpacing: CGFloat
  /// Button placement mode.
  public var buttonPosition: FKExpandableTextButtonPosition
  /// Expand/collapse animation duration. Minimum is `0.1`.
  public var animationDuration: TimeInterval

  /// Creates layout and animation style for the component.
  ///
  /// - Parameters:
  ///   - contentInsets: Insets around content.
  ///   - textButtonSpacing: Vertical spacing between text and button.
  ///   - buttonPosition: Placement mode for button.
  ///   - animationDuration: Animation duration for state transitions.
  public init(
    contentInsets: UIEdgeInsets = .zero,
    textButtonSpacing: CGFloat = 6,
    buttonPosition: FKExpandableTextButtonPosition = .bottomTrailing,
    animationDuration: TimeInterval = 0.25
  ) {
    self.contentInsets = contentInsets
    self.textButtonSpacing = max(0, textButtonSpacing)
    self.buttonPosition = buttonPosition
    self.animationDuration = max(0.1, animationDuration)
  }
}

/// Behavior options for interaction and state control.
public struct FKExpandableTextBehavior {
  /// Maximum number of lines in collapsed state. Minimum effective value is `1`.
  public var collapsedNumberOfLines: Int
  /// Allowed trigger sources for expand/collapse.
  public var triggerMode: FKExpandableTextTriggerMode
  /// Global interaction switch for this instance.
  public var isInteractionEnabled: Bool
  /// Whether to read/write state cache using `stateIdentifier`.
  public var usesStateCache: Bool
  /// Optional fixed state. When non-`nil`, interactive toggling is disabled.
  public var fixedState: FKExpandableTextDisplayState?

  /// Creates behavior options for state and interaction.
  ///
  /// - Parameters:
  ///   - collapsedNumberOfLines: Collapsed max line count.
  ///   - triggerMode: Trigger sources for state toggle.
  ///   - isInteractionEnabled: Whether user interaction is enabled.
  ///   - usesStateCache: Whether cache integration is enabled.
  ///   - fixedState: Optional fixed display state.
  public init(
    collapsedNumberOfLines: Int = 3,
    triggerMode: FKExpandableTextTriggerMode = .button,
    isInteractionEnabled: Bool = true,
    usesStateCache: Bool = true,
    fixedState: FKExpandableTextDisplayState? = nil
  ) {
    self.collapsedNumberOfLines = max(1, collapsedNumberOfLines)
    self.triggerMode = triggerMode
    self.isInteractionEnabled = isInteractionEnabled
    self.usesStateCache = usesStateCache
    self.fixedState = fixedState
  }
}

/// Full configuration for one FKExpandableText instance.
public struct FKExpandableTextConfiguration {
  /// Text rendering style.
  public var textStyle: FKExpandableTextTextStyle
  /// Expand/collapse button style.
  public var buttonStyle: FKExpandableTextButtonStyle
  /// Layout and animation style.
  public var layoutStyle: FKExpandableTextLayoutStyle
  /// Interaction and state behavior options.
  public var behavior: FKExpandableTextBehavior

  /// Creates the full configuration payload for one component instance.
  ///
  /// - Parameters:
  ///   - textStyle: Text style.
  ///   - buttonStyle: Button style.
  ///   - layoutStyle: Layout and animation style.
  ///   - behavior: Interaction behavior.
  public init(
    textStyle: FKExpandableTextTextStyle = FKExpandableTextTextStyle(),
    buttonStyle: FKExpandableTextButtonStyle = FKExpandableTextButtonStyle(),
    layoutStyle: FKExpandableTextLayoutStyle = FKExpandableTextLayoutStyle(),
    behavior: FKExpandableTextBehavior = FKExpandableTextBehavior()
  ) {
    self.textStyle = textStyle
    self.buttonStyle = buttonStyle
    self.layoutStyle = layoutStyle
    self.behavior = behavior
  }

  /// Builder helper for one-line configuration.
  ///
  /// - Parameter updates: Mutation closure that updates a local configuration copy.
  /// - Returns: A fully configured `FKExpandableTextConfiguration` value.
  public static func build(
    _ updates: (inout FKExpandableTextConfiguration) -> Void
  ) -> FKExpandableTextConfiguration {
    var configuration = FKExpandableTextConfiguration()
    updates(&configuration)
    return configuration
  }
}
