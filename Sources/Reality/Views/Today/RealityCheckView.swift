import SwiftUI

struct RealityCheckView: View {
  let summary: DailySummary
  let correction: String?

  var body: some View {
    RealityCard(tint: Color.green.opacity(0.08)) {
      VStack(alignment: .leading, spacing: 10) {
        Text("REALITY CHECK").realityEyebrow()
        if summary.hasEnoughEvidence {
          HStack(spacing: 24) {
            metric("Active", summary.activeDuration)
            metric("Away", summary.awayDuration)
            metric("Unknown", summary.unknownDuration)
          }
          if let leak = summary.largestRecoverableLeak {
            Text(
              "Largest recoverable leak: \(duration(leak.duration))\(leak.appName.map { " in \($0)" } ?? "")"
            )
            .font(.callout.weight(.semibold))
          }
          Text(correction ?? "Choose exactly one correction in Review.")
            .foregroundStyle(.secondary)
        } else {
          Text("Not enough evidence yet").font(.headline)
          Text("Reality waits for 30 minutes of active evidence before drawing conclusions.")
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func metric(_ label: String, _ value: TimeInterval) -> some View {
    VStack(alignment: .leading) {
      Text(duration(value)).font(.title3.bold())
      Text(label).font(.caption).foregroundStyle(.secondary)
    }
  }

  private func duration(_ value: TimeInterval) -> String {
    let minutes = Int(value / 60)
    return minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h \(minutes % 60)m"
  }
}
