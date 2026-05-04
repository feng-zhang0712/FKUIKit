import Foundation

/// Identifies which panel recipe in ``FKFilterPanelFactory`` serves a tab.
///
/// Built-in cases match previous string identifiers for analytics / ``RawRepresentable``.
/// Use ``custom(_:)`` for app-specific kinds and register a matching ``FKFilterPanelFactory/PanelSource``.
public enum FKFilterPanelKind: Hashable, Sendable {
  case hierarchy
  case dualHierarchy
  case gridPrimary
  case gridSecondary
  case tags
  case singleList
  case custom(String)
}

extension FKFilterPanelKind: RawRepresentable {
  public typealias RawValue = String

  public init?(rawValue: String) {
    switch rawValue {
    case "hierarchy": self = .hierarchy
    case "dualHierarchy": self = .dualHierarchy
    case "gridPrimary": self = .gridPrimary
    case "gridSecondary": self = .gridSecondary
    case "tags": self = .tags
    case "singleList": self = .singleList
    default:
      self = .custom(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .hierarchy: return "hierarchy"
    case .dualHierarchy: return "dualHierarchy"
    case .gridPrimary: return "gridPrimary"
    case .gridSecondary: return "gridSecondary"
    case .tags: return "tags"
    case .singleList: return "singleList"
    case .custom(let value): return value
    }
  }
}
