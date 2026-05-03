import Foundation

public extension IndexPath {
  /// Zero row in section `0` (common table default).
  static var fk_zero: IndexPath {
    IndexPath(row: 0, section: 0)
  }

  /// `true` when this path is the first row of the first section.
  var fk_isFirstRow: Bool {
    section == 0 && row == 0
  }
}
