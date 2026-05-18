import Foundation

/// How the coordinator repeats items when a track finishes.
public enum FKMediaLoopMode: String, Sendable, Equatable {
  case none
  case one
  case all
}
