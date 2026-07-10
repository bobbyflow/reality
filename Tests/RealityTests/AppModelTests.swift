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

  @Test("reflects live collector health and delegates pause immediately")
  func liveCollectorControl() {
    let collector = FakeCollector()
    let model = AppModel(collector: collector)

    model.startCollector()
    #expect(collector.startCount == 1)
    #expect(model.collectorStatus == .tracking)

    model.togglePause()
    #expect(collector.isPaused)
    #expect(model.collectorStatus == .paused)

    collector.report(.degraded(.accessibilityDenied))
    #expect(model.collectorStatus == .degraded)
    #expect(model.isTracking)
  }
}

@MainActor
private final class FakeCollector: CollectorControlling {
  var health: CollectorHealth = .stopped
  var healthDidChange: ((CollectorHealth) -> Void)?
  var startCount = 0
  var isPaused = false

  func start() {
    startCount += 1
    health = .healthy
    healthDidChange?(health)
  }

  func stop() {
    health = .stopped
    healthDidChange?(health)
  }

  func setPaused(_ paused: Bool) {
    isPaused = paused
    health = paused ? .paused : .healthy
    healthDidChange?(health)
  }

  func report(_ health: CollectorHealth) {
    self.health = health
    healthDidChange?(health)
  }
}
