import CoreGraphics
import Foundation

@MainActor
protocol IdleStateProviding: AnyObject {
  var idleDuration: TimeInterval { get }
}

@MainActor
final class IdleStateProvider: IdleStateProviding {
  var idleDuration: TimeInterval {
    CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)
  }
}
