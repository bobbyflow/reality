import Foundation
import Testing

@testable import Reality

@Suite("Today store")
@MainActor
struct TodayStoreTests {
  @Test("saving an intention persists normalized values and confirms the action")
  func saveIntention() throws {
    let fixture = try DatabaseFixture()
    let manager = try DatabaseManager(databaseURL: fixture.databaseURL)
    let suiteName = "RealityTodayTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    let store = TodayStore(
      activityRepository: GRDBActivityRepository(pool: manager.pool),
      evidenceRepository: GRDBCollectorEvidenceRepository(pool: manager.pool),
      defaults: defaults)

    store.saveIntention(
      essential: "  Finish the Dubai deck  ", optionalOutcomes: ["", " Send update "])

    #expect(store.intention.essential == "Finish the Dubai deck")
    #expect(store.intention.optionalOutcomes == ["Send update"])
    #expect(defaults.string(forKey: "today.essential") == "Finish the Dubai deck")
    #expect(defaults.stringArray(forKey: "today.optional") == ["Send update"])
    #expect(store.intentionSaveConfirmation == "Saved")

    store.clearIntentionSaveConfirmation()
    #expect(store.intentionSaveConfirmation == nil)
  }
}
