import Foundation
import Testing

@testable import Reality

@Suite("Classification rule engine")
struct RuleEngineTests {
  private let base = Date(timeIntervalSince1970: 3_000_000)

  @Test("correction outranks user rules and defaults")
  func correctionPriority() {
    let segment = activeSegment(bundleID: "com.apple.Safari")
    let user = ClassificationRule(
      id: uuid(1), appBundleID: "com.apple.Safari", category: .learning, priority: 10,
      origin: .user)
    let fallback = ClassificationRule(
      id: uuid(2), appBundleID: "com.apple.Safari", category: .drift, priority: 100,
      origin: .defaultRule)
    let correction = BlockCorrection(segmentID: segment.id, category: .focus)

    let decision = RuleEngine().classify(
      segment, correction: correction, userRules: [user], defaultRules: [fallback])

    #expect(decision.category == .focus)
    #expect(decision.basis == .correction)
  }

  @Test("user rule outranks defaults regardless of numeric priority")
  func userRulePriority() {
    let segment = activeSegment(bundleID: "com.apple.Terminal")
    let decision = RuleEngine().classify(
      segment,
      userRules: [
        ClassificationRule(
          id: uuid(1), appBundleID: "com.apple.Terminal", category: .focus, priority: 1,
          origin: .user
        )
      ],
      defaultRules: [
        ClassificationRule(
          id: uuid(2), appBundleID: "com.apple.Terminal", category: .admin, priority: 999,
          origin: .defaultRule
        )
      ]
    )

    #expect(decision.category == .focus)
    #expect(decision.basis == .userRule(uuid(1)))
  }

  @Test("highest priority matching rule wins with stable identifier tie-break")
  func deterministicRuleOrder() {
    let segment = activeSegment(bundleID: "com.apple.Safari")
    let lowID = ClassificationRule(
      id: uuid(1), appBundleID: "com.apple.Safari", category: .learning, priority: 10,
      origin: .user)
    let highID = ClassificationRule(
      id: uuid(2), appBundleID: "com.apple.Safari", category: .drift, priority: 10,
      origin: .user)

    let first = RuleEngine().classify(segment, userRules: [highID, lowID])
    let second = RuleEngine().classify(segment, userRules: [lowID, highID])

    #expect(first == second)
    #expect(first.category == .learning)
  }

  @Test("non-active states remain uncategorized and unknown apps are explicit")
  func stateAndUnknown() {
    let away = activeSegment(bundleID: nil, state: .away)
    let active = activeSegment(bundleID: "unknown.bundle")

    #expect(RuleEngine().classify(away).category == nil)
    #expect(RuleEngine().classify(active).category == .unknown)
    #expect(RuleEngine().classify(active).basis == .unmatched)
  }

  @Test("classification edits expose this block or future exact-app matches")
  func editScopes() throws {
    let segment = activeSegment(bundleID: "com.apple.Terminal")
    let engine = RuleEngine()

    #expect(engine.availableEditScopes(for: segment) == [.thisBlock, .futureMatches])
    #expect(
      try engine.makeEdit(for: segment, category: .focus, scope: .thisBlock)
        == .correction(BlockCorrection(segmentID: segment.id, category: .focus))
    )
    guard
      case .rule(let rule) = try engine.makeEdit(
        for: segment, category: .learning, scope: .futureMatches)
    else {
      Issue.record("Expected future-match rule")
      return
    }
    #expect(rule.appBundleID == "com.apple.Terminal")
    #expect(rule.category == .learning)
    #expect(rule.origin == .user)
  }

  private func activeSegment(
    bundleID: String?, state: ActivityState = .active
  ) -> ActivitySegment {
    ActivitySegment(
      id: uuid(9), start: base, end: base.addingTimeInterval(60), appBundleID: bundleID,
      appName: bundleID, state: state, source: .automatic, quality: .exact, category: nil,
      timezoneID: "UTC", derivationVersion: 1)
  }

  private func uuid(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
  }
}
