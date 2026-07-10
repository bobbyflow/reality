import CoreGraphics
import Foundation

@MainActor
protocol IdleStateProviding: AnyObject {
  var idleDuration: TimeInterval { get }
}

@MainActor
final class IdleStateProvider: IdleStateProviding {
  private let secondsSinceLastEvent: (CGEventType) -> TimeInterval

  init(
    secondsSinceLastEvent: @escaping (CGEventType) -> TimeInterval = { eventType in
      CGEventSource.secondsSinceLastEventType(
        .combinedSessionState, eventType: eventType)
    }
  ) {
    self.secondsSinceLastEvent = secondsSinceLastEvent
  }

  var idleDuration: TimeInterval {
    // CoreGraphics defines raw UInt32.max as its any-input sentinel.
    let anyInput = CGEventType(rawValue: UInt32.max)!
    return secondsSinceLastEvent(anyInput)
  }
}
