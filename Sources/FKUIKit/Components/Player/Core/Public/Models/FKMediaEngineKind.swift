import Foundation

/// Identifies which playback engine implementation is active.
public enum FKMediaEngineKind: String, Sendable, Equatable, CaseIterable {
  case avFoundation
  case extended
}
