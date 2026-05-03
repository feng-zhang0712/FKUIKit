import Foundation

/// Tab identifiers for the anchored dropdown sample screens.
enum AnchoredDropdownExampleTabID: String, CaseIterable, Hashable {
  case sort
  case filters
  case search

  var title: String {
    switch self {
    case .sort: return "Sort"
    case .filters: return "Filters"
    case .search: return "Search"
    }
  }
}
