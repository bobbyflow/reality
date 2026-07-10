import Foundation

@MainActor
protocol CollectorClock: AnyObject {
  var now: Date { get }
  var uptime: TimeInterval { get }
}

@MainActor
final class SystemCollectorClock: CollectorClock {
  var now: Date { .now }
  var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }
}
