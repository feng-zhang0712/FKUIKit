//
// FKSwipeActionItem.swift
//
// Action item model for FKSwipeAction buttons.
//

import UIKit

/// Built-in semantic action identifiers.
public enum FKSwipeActionKind: String, Hashable, Sendable {
  /// Destructive delete action.
  case delete
  /// Edit action.
  case edit
  /// Pin action.
  case pin
  /// Mark action.
  case mark
  /// Favorite action.
  case favorite
  /// Generic overflow action.
  case more
  /// Custom action defined by caller.
  case custom
}

/// Display style for one swipe action button.
public struct FKSwipeActionItemStyle {
  /// Preferred fixed width. If `nil`, the button uses intrinsic content width.
  public var fixedWidth: CGFloat?
  /// Minimum width used when auto-sizing.
  ///
  /// The minimum effective value is `44`.
  public var minimumWidth: CGFloat
  /// Button corner radius.
  ///
  /// Use `0` for a rectangle style.
  public var cornerRadius: CGFloat
  /// Internal content padding.
  public var contentInsets: UIEdgeInsets
  /// Spacing between image and title.
  public var imageTitleSpacing: CGFloat
  /// Button background color.
  public var backgroundColor: UIColor
  /// Highlight background color.
  public var highlightedBackgroundColor: UIColor
  /// Title text color.
  public var titleColor: UIColor
  /// Title font.
  public var titleFont: UIFont
  /// Icon tint color.
  public var imageTintColor: UIColor?
  /// Explicit icon size. If `nil`, uses image natural size.
  public var imageSize: CGSize?

  /// Creates a style object.
  ///
  /// - Parameters:
  ///   - fixedWidth: Optional fixed width for deterministic layout.
  ///   - minimumWidth: Minimum width used by intrinsic sizing.
  ///   - cornerRadius: Corner radius for rounded visual style.
  ///   - contentInsets: Internal spacing around image/title stack.
  ///   - imageTitleSpacing: Spacing between image and title.
  ///   - backgroundColor: Normal background color.
  ///   - highlightedBackgroundColor: Highlight-state background color.
  ///   - titleColor: Title color in normal state.
  ///   - titleFont: Title font.
  ///   - imageTintColor: Optional icon tint color.
  ///   - imageSize: Optional explicit icon size.
  public init(
    fixedWidth: CGFloat? = nil,
    minimumWidth: CGFloat = 64,
    cornerRadius: CGFloat = 0,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12),
    imageTitleSpacing: CGFloat = 6,
    backgroundColor: UIColor,
    highlightedBackgroundColor: UIColor? = nil,
    titleColor: UIColor = .white,
    titleFont: UIFont = .systemFont(ofSize: 15, weight: .semibold),
    imageTintColor: UIColor? = nil,
    imageSize: CGSize? = nil
  ) {
    self.fixedWidth = fixedWidth
    self.minimumWidth = max(44, minimumWidth)
    self.cornerRadius = max(0, cornerRadius)
    self.contentInsets = contentInsets
    self.imageTitleSpacing = max(0, imageTitleSpacing)
    self.backgroundColor = backgroundColor
    self.highlightedBackgroundColor = highlightedBackgroundColor ?? backgroundColor.withAlphaComponent(0.78)
    self.titleColor = titleColor
    self.titleFont = titleFont
    self.imageTintColor = imageTintColor
    self.imageSize = imageSize
  }
}

/// One action button descriptor.
public struct FKSwipeActionItem {
  /// Action identity for analytics or branching.
  public var kind: FKSwipeActionKind
  /// Unique identifier for diff/update.
  public var identifier: String
  /// Button title.
  public var title: String?
  /// Button icon.
  public var image: UIImage?
  /// Whether the action can be tapped.
  public var isEnabled: Bool
  /// Whether tapping this action auto closes the opened state.
  public var autoCloseOnTap: Bool
  /// Whether tapping requires a confirm dialog first.
  public var requiresConfirmation: Bool
  /// Confirmation title.
  public var confirmationTitle: String?
  /// Confirmation message.
  public var confirmationMessage: String?
  /// Confirm action title.
  public var confirmationActionTitle: String
  /// Cancel action title.
  public var confirmationCancelTitle: String
  /// Visual style.
  public var style: FKSwipeActionItemStyle
  /// Tap callback.
  ///
  /// The callback runs on the main actor and provides contextual metadata.
  public var handler: (@MainActor (FKSwipeActionContext) -> Void)?

  /// Creates an action item.
  ///
  /// - Parameters:
  ///   - kind: Semantic action kind.
  ///   - identifier: Stable item identifier for analytics or diff usage.
  ///   - title: Optional title text.
  ///   - image: Optional icon image.
  ///   - isEnabled: Whether this action is interactable.
  ///   - autoCloseOnTap: Whether opened state closes after callback.
  ///   - requiresConfirmation: Whether confirmation alert is shown before callback.
  ///   - confirmationTitle: Alert title for dangerous actions.
  ///   - confirmationMessage: Alert message for dangerous actions.
  ///   - confirmationActionTitle: Confirm button title.
  ///   - confirmationCancelTitle: Cancel button title.
  ///   - style: Visual style for the rendered button.
  ///   - handler: Optional tap callback.
  public init(
    kind: FKSwipeActionKind = .custom,
    identifier: String = UUID().uuidString,
    title: String? = nil,
    image: UIImage? = nil,
    isEnabled: Bool = true,
    autoCloseOnTap: Bool = true,
    requiresConfirmation: Bool = false,
    confirmationTitle: String? = nil,
    confirmationMessage: String? = nil,
    confirmationActionTitle: String = "Confirm",
    confirmationCancelTitle: String = "Cancel",
    style: FKSwipeActionItemStyle,
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) {
    self.kind = kind
    self.identifier = identifier
    self.title = title
    self.image = image
    self.isEnabled = isEnabled
    self.autoCloseOnTap = autoCloseOnTap
    self.requiresConfirmation = requiresConfirmation
    self.confirmationTitle = confirmationTitle
    self.confirmationMessage = confirmationMessage
    self.confirmationActionTitle = confirmationActionTitle
    self.confirmationCancelTitle = confirmationCancelTitle
    self.style = style
    self.handler = handler
  }
}

public extension FKSwipeActionItem {
  /// Built-in delete action.
  ///
  /// - Parameters:
  ///   - title: Optional action title shown on the button and confirmation dialog.
  ///   - image: Optional icon image.
  ///   - requiresConfirmation: Whether confirmation dialog is required.
  ///   - style: Visual style for this action.
  ///   - handler: Callback executed after optional confirmation.
  /// - Returns: A delete-configured action item.
  static func delete(
    title: String? = "Delete",
    image: UIImage? = nil,
    requiresConfirmation: Bool = true,
    style: FKSwipeActionItemStyle = FKSwipeActionItemStyle(backgroundColor: .systemRed),
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) -> FKSwipeActionItem {
    FKSwipeActionItem(
      kind: .delete,
      title: title,
      image: image,
      requiresConfirmation: requiresConfirmation,
      confirmationTitle: title,
      confirmationMessage: "This action cannot be undone.",
      confirmationActionTitle: title ?? "Delete",
      style: style,
      handler: handler
    )
  }

  /// Built-in edit action.
  ///
  /// - Parameters:
  ///   - title: Optional action title.
  ///   - image: Optional icon image.
  ///   - style: Visual style for this action.
  ///   - handler: Callback executed on tap.
  /// - Returns: An edit-configured action item.
  static func edit(
    title: String? = "Edit",
    image: UIImage? = nil,
    style: FKSwipeActionItemStyle = FKSwipeActionItemStyle(backgroundColor: .systemBlue),
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) -> FKSwipeActionItem {
    FKSwipeActionItem(kind: .edit, title: title, image: image, style: style, handler: handler)
  }

  /// Built-in pin action.
  ///
  /// - Parameters:
  ///   - title: Optional action title.
  ///   - image: Optional icon image.
  ///   - style: Visual style for this action.
  ///   - handler: Callback executed on tap.
  /// - Returns: A pin-configured action item.
  static func pin(
    title: String? = "Pin",
    image: UIImage? = nil,
    style: FKSwipeActionItemStyle = FKSwipeActionItemStyle(backgroundColor: .systemOrange),
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) -> FKSwipeActionItem {
    FKSwipeActionItem(kind: .pin, title: title, image: image, style: style, handler: handler)
  }

  /// Built-in mark action.
  ///
  /// - Parameters:
  ///   - title: Optional action title.
  ///   - image: Optional icon image.
  ///   - style: Visual style for this action.
  ///   - handler: Callback executed on tap.
  /// - Returns: A mark-configured action item.
  static func mark(
    title: String? = "Mark",
    image: UIImage? = nil,
    style: FKSwipeActionItemStyle = FKSwipeActionItemStyle(backgroundColor: .systemGreen),
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) -> FKSwipeActionItem {
    FKSwipeActionItem(kind: .mark, title: title, image: image, style: style, handler: handler)
  }

  /// Built-in favorite action.
  ///
  /// - Parameters:
  ///   - title: Optional action title.
  ///   - image: Optional icon image.
  ///   - style: Visual style for this action.
  ///   - handler: Callback executed on tap.
  /// - Returns: A favorite-configured action item.
  static func favorite(
    title: String? = "Favorite",
    image: UIImage? = nil,
    style: FKSwipeActionItemStyle = FKSwipeActionItemStyle(backgroundColor: .systemPink),
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) -> FKSwipeActionItem {
    FKSwipeActionItem(kind: .favorite, title: title, image: image, style: style, handler: handler)
  }

  /// Built-in more action.
  ///
  /// - Parameters:
  ///   - title: Optional action title.
  ///   - image: Optional icon image.
  ///   - style: Visual style for this action.
  ///   - handler: Callback executed on tap.
  /// - Returns: A more-configured action item.
  static func more(
    title: String? = "More",
    image: UIImage? = nil,
    style: FKSwipeActionItemStyle = FKSwipeActionItemStyle(backgroundColor: .systemGray),
    handler: (@MainActor (FKSwipeActionContext) -> Void)? = nil
  ) -> FKSwipeActionItem {
    FKSwipeActionItem(kind: .more, title: title, image: image, style: style, handler: handler)
  }
}
