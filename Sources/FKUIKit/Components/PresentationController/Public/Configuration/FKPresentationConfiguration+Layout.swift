import UIKit

public extension FKPresentationConfiguration {
  public enum Layout {
    case bottomSheet(SheetConfiguration)
    case topSheet(SheetConfiguration)
    case center(CenterConfiguration)
    case anchor(FKAnchorConfiguration)
    case edge(UIRectEdge)
  }
}
