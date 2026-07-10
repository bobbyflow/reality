import CoreGraphics
import Testing

@testable import Reality

@Suite("Idle state provider")
@MainActor
struct IdleStateProviderTests {
  @Test("queries the CoreGraphics any-input sentinel instead of the null event")
  func anyInputEvent() {
    var queriedEventType: CGEventType?
    let provider = IdleStateProvider { eventType in
      queriedEventType = eventType
      return 12.5
    }

    #expect(provider.idleDuration == 12.5)
    #expect(queriedEventType?.rawValue == UInt32.max)
    #expect(queriedEventType != .null)
  }
}
