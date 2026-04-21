//
// FKStarRating+IB.swift
//
// Interface Builder attributes for FKStarRating.
//

import UIKit

public extension FKStarRating {
  /// Star count exposed for Interface Builder.
  @IBInspectable
  var fk_starCount: Int {
    get { configuration.starCount }
    set { configure { $0.starCount = newValue } }
  }

  /// Rating exposed for Interface Builder.
  @IBInspectable
  var fk_rating: CGFloat {
    get { rating }
    set { setRating(newValue, animated: false, notify: false) }
  }

  /// Star spacing exposed for Interface Builder.
  @IBInspectable
  var fk_starSpacing: CGFloat {
    get { configuration.starSpacing }
    set { configure { $0.starSpacing = newValue } }
  }

  /// Editability switch exposed for Interface Builder.
  @IBInspectable
  var fk_isEditable: Bool {
    get { configuration.isEditable }
    set { configure { $0.isEditable = newValue } }
  }
}
