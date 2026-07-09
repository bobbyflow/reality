import Testing

@testable import Reality

@Suite("App model truthfulness")
@MainActor
struct AppModelTests {
  @Test("starts empty and never claims automatic collection")
  func truthfulInitialState() {
    let model = AppModel()

    #expect(model.activities.isEmpty)
    #expect(model.collectorStatus == .unavailable)
    #expect(model.isTracking == false)
    #expect(model.emptyStateMessage == "No activity recorded yet.")
    #expect(model.collectorStatus.detail == "Automatic tracking is not connected.")
  }

  @Test("cannot pause a collector that does not exist")
  func unavailableCollectorCannotBePaused() {
    let model = AppModel()

    model.togglePause()

    #expect(model.collectorStatus == .unavailable)
    #expect(model.canTogglePause == false)
  }

  @Test("toggles a healthy collector between tracking and paused")
  func healthyCollectorCanBePausedAndResumed() {
    let model = AppModel(collectorStatus: .tracking)

    model.togglePause()
    #expect(model.collectorStatus == .paused)
    #expect(model.isTracking == false)

    model.togglePause()
    #expect(model.collectorStatus == .tracking)
    #expect(model.isTracking == true)
  }

  @Test("selection defaults to today and supports every primary section")
  func navigationSelection() {
    let model = AppModel()

    #expect(model.selection == .today)
    #expect(NavigationSection.allCases == [.today, .review, .patterns])

    model.selection = .review
    #expect(model.selection == .review)
  }
}
