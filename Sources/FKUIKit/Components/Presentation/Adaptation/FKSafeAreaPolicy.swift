import UIKit

/// Defines whether safe area is respected by container bounds or only by inner content.
public enum FKSafeAreaPolicy: Equatable {
  /// Container edges can touch screen edges while content handles safe area internally.
  ///
  /// Use this for bottom/top sheets that should visually attach to screen edges.
  case contentRespectsSafeArea
  /// Container itself keeps spacing from safe area boundaries.
  ///
  /// Use this when the presented chrome itself must avoid notches/home-indicator regions.
  case containerRespectsSafeArea
}
