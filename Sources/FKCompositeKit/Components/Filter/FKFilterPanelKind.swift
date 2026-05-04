/// Extensible panel identifier. Use predefined static values or custom string literals.
public struct FKFilterPanelKind: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.rawValue = value }

  // Generic presets.
  public static let hierarchy: FKFilterPanelKind = "hierarchy"
  public static let dualHierarchy: FKFilterPanelKind = "dualHierarchy"
  public static let gridPrimary: FKFilterPanelKind = "gridPrimary"
  public static let gridSecondary: FKFilterPanelKind = "gridSecondary"
  public static let tags: FKFilterPanelKind = "tags"
  public static let singleList: FKFilterPanelKind = "singleList"
}
