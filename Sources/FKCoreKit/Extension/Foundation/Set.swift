import Foundation

public extension Set {
  /// Returns a new set with `newMember` inserted when missing.
  func fk_inserting(_ newMember: Element) -> Set<Element> {
    var copy = self
    copy.insert(newMember)
    return copy
  }

  /// Returns a new set with `member` removed when present.
  func fk_removing(_ member: Element) -> Set<Element> {
    var copy = self
    copy.remove(member)
    return copy
  }

  /// Inserts all elements from `sequence`.
  mutating func fk_formUnion<S: Sequence>(from sequence: S) where S.Element == Element {
    formUnion(sequence)
  }
}
