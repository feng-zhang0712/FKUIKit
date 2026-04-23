import Foundation
import UIKit

/// Clock abstraction for deterministic tests.
protocol FKToastClock: Sendable {
  func now() -> Date
}

struct FKSystemToastClock: FKToastClock {
  func now() -> Date { Date() }
}

/// Internal request model owned by the queue actor.
struct FKToastRequest: @unchecked Sendable {
  let id: UUID
  let content: FKToastContent
  let icon: UIImage?
  let configuration: FKToastConfiguration
  let hooks: FKToastLifecycleHooks
  let actionHandler: (@MainActor () -> Void)?
  let secondaryActionHandler: (@MainActor () -> Void)?
  let createdAt: Date

  var deduplicationKey: String {
    switch content {
    case let .message(message):
      return "\(configuration.kind)-\(configuration.style)-\(message)"
    case let .titleSubtitle(title, subtitle):
      return "\(configuration.kind)-\(configuration.style)-\(title)-\(subtitle)"
    case .customView:
      return "\(configuration.kind)-custom"
    }
  }
}

/// Pure queue policy actor that can be tested without UIKit.
actor FKToastQueueActor {
  private var waiting: [FKToastRequest] = []
  private var displaying: [UUID: FKToastRequest] = [:]
  private let clock: FKToastClock

  init(clock: FKToastClock = FKSystemToastClock()) {
    self.clock = clock
  }

  func enqueue(_ request: FKToastRequest) -> FKToastRequest? {
    let queue = request.configuration.queue
    let current = displaying.values.sorted { $0.configuration.priority < $1.configuration.priority }
    let shouldPreempt = queue.allowPriorityPreemption && current.contains { $0.configuration.priority < request.configuration.priority }
    if shouldPreempt {
      return request
    }
    switch queue.arrivalPolicy {
    case .queue:
      waiting.append(request)
    case .replaceCurrent:
      waiting.removeAll()
      waiting.append(request)
    case .dropNew:
      break
    case .coalesce:
      coalesce(request)
    case .interruptAndRequeueCurrent:
      waiting.insert(request, at: 0)
    }
    return nil
  }

  func claimNext(maxCount: Int) -> [FKToastRequest] {
    guard displaying.count < maxCount, !waiting.isEmpty else { return [] }
    let available = max(0, maxCount - displaying.count)
    let sorted = waiting.enumerated().sorted { lhs, rhs in
      lhs.element.configuration.priority > rhs.element.configuration.priority
    }
    let selected = sorted.prefix(available).map(\.element)
    let ids = Set(selected.map(\.id))
    waiting.removeAll { ids.contains($0.id) }
    for request in selected {
      displaying[request.id] = request
    }
    return selected
  }

  func markDismissed(id: UUID) {
    displaying[id] = nil
  }

  func request(for id: UUID) -> FKToastRequest? {
    displaying[id]
  }

  func clear() -> [UUID] {
    waiting.removeAll()
    let ids = Array(displaying.keys)
    displaying.removeAll()
    return ids
  }

  private func coalesce(_ incoming: FKToastRequest) {
    let deadline = clock.now().addingTimeInterval(-incoming.configuration.queue.deduplicationWindow)
    let duplicateExists = waiting.contains {
      $0.deduplicationKey == incoming.deduplicationKey && $0.createdAt >= deadline
    } || displaying.values.contains {
      $0.deduplicationKey == incoming.deduplicationKey && $0.createdAt >= deadline
    }
    if !duplicateExists {
      waiting.append(incoming)
    }
  }
}
