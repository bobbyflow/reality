import Foundation
import Testing

@testable import Reality

@Suite("Review store")
@MainActor
struct ReviewStoreTests {
  @Test("withholds review conclusions until evidence is sufficient")
  func evidenceGate() {
    let store = makeStore()
    let summary = DailySummary.empty

    store.prepare(summary: summary, intention: DailyIntention(essential: "Ship the build"))

    #expect(store.isReady == false)
    #expect(store.plannedVersusActual == nil)
    #expect(store.recoverableLeak == nil)
  }

  @Test("compares intention to evidence and stores exactly one correction")
  func reviewAndCorrection() throws {
    let summary = DailySummary(
      evidenceDuration: 3_600,
      activeDuration: 3_000,
      awayDuration: 600,
      unknownDuration: 0,
      categoryDurations: [.focus: 1_800, .drift: 1_200],
      largestRecoverableLeak: RecoverableLeak(
        start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 1_300),
        duration: 1_200, appName: "Safari"),
      hasEnoughEvidence: true)
    let store = makeStore()
    store.prepare(summary: summary, intention: DailyIntention(essential: "Write proposal"))

    #expect(store.isReady)
    #expect(store.plannedVersusActual?.contains("Write proposal") == true)
    #expect(store.recoverableLeak?.duration == 1_200)

    try store.setCorrection("Block Safari until lunch")
    try store.setCorrection("Write before opening Safari")
    #expect(store.correction == "Write before opening Safari")
    #expect(store.corrections.count == 1)
  }

  @Test("rejects blank corrections")
  func blankCorrection() {
    let store = makeStore()
    do {
      try store.setCorrection("   ")
      Issue.record("Expected blank correction rejection")
    } catch let error as ReviewStoreError {
      #expect(error == .blankCorrection)
    } catch {
      Issue.record("Unexpected error")
    }
  }

  private func makeStore() -> ReviewStore {
    let name = "RealityReviewTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return ReviewStore(defaults: defaults)
  }
}
