import Foundation

enum ClassificationRuleOrigin: String, Equatable, Sendable {
  case user
  case defaultRule
}

struct ClassificationRule: Identifiable, Equatable, Sendable {
  let id: UUID
  let appBundleID: String
  let category: ActivityCategory
  let priority: Int
  let origin: ClassificationRuleOrigin
}

struct BlockCorrection: Equatable, Sendable {
  let segmentID: UUID
  let category: ActivityCategory
}

enum ClassificationBasis: Equatable, Sendable {
  case correction
  case userRule(UUID)
  case defaultRule(UUID)
  case unmatched
  case notApplicable
}

struct ClassificationDecision: Equatable, Sendable {
  let category: ActivityCategory?
  let basis: ClassificationBasis
}

enum ClassificationEditScope: Equatable, Sendable {
  case thisBlock
  case futureMatches
}

enum ClassificationEdit: Equatable, Sendable {
  case correction(BlockCorrection)
  case rule(ClassificationRule)
}

enum ClassificationEditError: Error, Equatable {
  case notClassifiable
  case missingApplicationIdentity
}

struct RuleEngine: Sendable {
  func availableEditScopes(for segment: ActivitySegment) -> [ClassificationEditScope] {
    guard segment.state == .active else { return [] }
    return segment.appBundleID == nil ? [.thisBlock] : [.thisBlock, .futureMatches]
  }

  func makeEdit(
    for segment: ActivitySegment,
    category: ActivityCategory,
    scope: ClassificationEditScope
  ) throws -> ClassificationEdit {
    guard segment.state == .active else {
      throw ClassificationEditError.notClassifiable
    }
    switch scope {
    case .thisBlock:
      return .correction(BlockCorrection(segmentID: segment.id, category: category))
    case .futureMatches:
      guard let appBundleID = segment.appBundleID else {
        throw ClassificationEditError.missingApplicationIdentity
      }
      return .rule(
        ClassificationRule(
          id: StableIdentifier.make(["user-rule", appBundleID, category.rawValue]),
          appBundleID: appBundleID,
          category: category,
          priority: 0,
          origin: .user
        ))
    }
  }

  func classify(
    _ segment: ActivitySegment,
    correction: BlockCorrection? = nil,
    userRules: [ClassificationRule] = [],
    defaultRules: [ClassificationRule] = []
  ) -> ClassificationDecision {
    guard segment.state == .active else {
      return ClassificationDecision(category: nil, basis: .notApplicable)
    }
    if let correction, correction.segmentID == segment.id {
      return ClassificationDecision(category: correction.category, basis: .correction)
    }
    if let rule = bestMatch(in: userRules, for: segment.appBundleID) {
      return ClassificationDecision(category: rule.category, basis: .userRule(rule.id))
    }
    if let rule = bestMatch(in: defaultRules, for: segment.appBundleID) {
      return ClassificationDecision(category: rule.category, basis: .defaultRule(rule.id))
    }
    return ClassificationDecision(category: .unknown, basis: .unmatched)
  }

  func applying(
    to segment: ActivitySegment,
    correction: BlockCorrection? = nil,
    userRules: [ClassificationRule] = [],
    defaultRules: [ClassificationRule] = []
  ) -> ActivitySegment {
    let decision = classify(
      segment, correction: correction, userRules: userRules, defaultRules: defaultRules)
    return ActivitySegment(
      id: segment.id,
      start: segment.start,
      end: segment.end,
      appBundleID: segment.appBundleID,
      appName: segment.appName,
      state: segment.state,
      source: segment.source,
      quality: segment.quality,
      category: decision.category,
      timezoneID: segment.timezoneID,
      derivationVersion: segment.derivationVersion
    )
  }

  private func bestMatch(
    in rules: [ClassificationRule], for appBundleID: String?
  ) -> ClassificationRule? {
    guard let appBundleID else { return nil }
    return
      rules
      .filter { $0.appBundleID == appBundleID }
      .sorted {
        if $0.priority != $1.priority { return $0.priority > $1.priority }
        return $0.id.uuidString < $1.id.uuidString
      }
      .first
  }
}
