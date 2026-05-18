import Foundation

/// Result of probing a URL or file for container, delivery, and suggested engine.
public struct FKMediaFormatDescriptor: Sendable, Equatable {
  public let container: FKMediaContainer
  public let mediaType: FKMediaType
  public let suggestedEngine: FKMediaEngineKind
  public let delivery: FKMediaDelivery
  public let isLive: Bool
  public let allowsAVFoundation: Bool
  public let allowsExtended: Bool

  public init(
    container: FKMediaContainer,
    mediaType: FKMediaType,
    suggestedEngine: FKMediaEngineKind,
    delivery: FKMediaDelivery,
    isLive: Bool,
    allowsAVFoundation: Bool,
    allowsExtended: Bool
  ) {
    self.container = container
    self.mediaType = mediaType
    self.suggestedEngine = suggestedEngine
    self.delivery = delivery
    self.isLive = isLive
    self.allowsAVFoundation = allowsAVFoundation
    self.allowsExtended = allowsExtended
  }
}
