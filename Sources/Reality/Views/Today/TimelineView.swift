import SwiftUI

struct TimelineView: View {
  @Bindable var store: TodayStore
  @State private var selectedAway: TimelineBlock?

  var body: some View {
    RealityCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Text("TODAY’S TIMELINE").realityEyebrow()
          Spacer()
          Text("\(store.blocks.count) blocks")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        ForEach(store.blocks) { block in
          HStack(spacing: 14) {
            Text(block.start.formatted(date: .omitted, time: .shortened))
              .font(.system(.caption, design: .monospaced))
              .foregroundStyle(.secondary)
              .frame(width: 58, alignment: .trailing)
            RoundedRectangle(cornerRadius: 3)
              .fill(color(for: block))
              .frame(width: 5, height: 34)
            VStack(alignment: .leading, spacing: 2) {
              Text(title(for: block)).font(.callout.weight(.semibold))
              Text(detail(for: block)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(duration(block.end.timeIntervalSince(block.start)))
              .font(.caption.weight(.medium))
            if block.state == .away {
              Button(store.awayAnnotations[block.sourceID] ?? "Label") {
                selectedAway = block
              }
              .buttonStyle(.borderless)
            }
          }
          if block.id != store.blocks.last?.id { Divider() }
        }
      }
    }
    .sheet(item: $selectedAway) { block in
      AwayAnnotationSheet(store: store, block: block)
    }
  }

  private func title(for block: TimelineBlock) -> String {
    if let annotation = store.awayAnnotations[block.sourceID] { return annotation }
    return block.title ?? block.appName ?? block.state.rawValue.capitalized
  }

  private func detail(for block: TimelineBlock) -> String {
    block.category?.rawValue.capitalized ?? block.state.rawValue.capitalized
  }

  private func duration(_ value: TimeInterval) -> String {
    let minutes = max(1, Int(value / 60))
    return minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h \(minutes % 60)m"
  }

  private func color(for block: TimelineBlock) -> Color {
    switch block.category {
    case .focus: .green
    case .collaboration: .blue
    case .admin: .orange
    case .learning: .purple
    case .drift: .red
    case .recovery: .cyan
    case .unknown, nil: .gray
    }
  }
}
