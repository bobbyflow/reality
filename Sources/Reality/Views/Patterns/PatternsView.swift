import SwiftUI

struct PatternsView: View {
  let summary: DailySummary

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        Text("Patterns").font(.system(size: 38, weight: .bold, design: .serif))
        if summary.hasEnoughEvidence {
          RealityCard {
            VStack(alignment: .leading, spacing: 14) {
              Text("TODAY’S CATEGORY MIX").realityEyebrow()
              ForEach(ActivityCategory.allCases, id: \.self) { category in
                let value = summary.categoryDurations[category, default: 0]
                if value > 0 {
                  HStack {
                    Text(category.rawValue.capitalized).frame(width: 110, alignment: .leading)
                    ProgressView(value: value, total: max(1, summary.activeDuration))
                    Text("\(Int(value / 60))m").font(.caption).frame(
                      width: 48, alignment: .trailing)
                  }
                }
              }
            }
          }
          Text("Multi-day claims remain hidden until Reality has several complete days.")
            .font(.caption).foregroundStyle(.secondary)
        } else {
          ContentUnavailableView(
            "Patterns need evidence", systemImage: "chart.line.uptrend.xyaxis",
            description: Text(
              "Use Reality normally. It will not invent a trend from a partial day."))
        }
      }
      .frame(maxWidth: 900, alignment: .leading)
      .padding(32)
    }
    .navigationTitle("Patterns")
  }
}
