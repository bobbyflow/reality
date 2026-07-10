import SwiftUI

struct TodayView: View {
  @Bindable var model: AppModel
  @State private var showingCapture = false
  @State private var essential = ""
  @State private var optionalOne = ""
  @State private var optionalTwo = ""

  private var dateLabel: String {
    Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        header
        truthGrid
        timelineSection
        if let store = model.todayStore {
          RealityCheckView(summary: store.summary, correction: model.reviewStore?.correction)
        }
        privacyFooter
      }
      .frame(maxWidth: 1_050, alignment: .leading)
      .padding(32)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .navigationTitle("Today")
    .toolbar {
      Button("Add Activity", systemImage: "plus") { showingCapture = true }
        .disabled(model.todayStore == nil)
    }
    .sheet(isPresented: $showingCapture) {
      if let store = model.todayStore { CaptureView(store: store) }
    }
    .onAppear {
      guard let intention = model.todayStore?.intention else { return }
      essential = intention.essential
      optionalOne = intention.optionalOutcomes.first ?? ""
      optionalTwo = intention.optionalOutcomes.dropFirst().first ?? ""
    }
    .onChange(of: model.captureRequestID) { _, _ in showingCapture = true }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(dateLabel.uppercased())
        .font(.caption.weight(.bold))
        .tracking(1.4)
        .foregroundStyle(.secondary)
      Text("Here’s where your day went.")
        .font(.system(size: 38, weight: .bold, design: .serif))
        .tracking(-1)
      Text("Reality starts with evidence, not assumptions.")
        .foregroundStyle(.secondary)
    }
  }

  private var truthGrid: some View {
    HStack(spacing: 16) {
      statusCard
      intentionCard
    }
  }

  private var statusCard: some View {
    RealityCard {
      HStack(alignment: .top, spacing: 16) {
        Image(systemName: model.collectorStatus.systemImage)
          .font(.system(size: 30))
          .foregroundStyle(.secondary)
          .frame(width: 44, height: 44)
          .background(.quaternary, in: RoundedRectangle(cornerRadius: 11))

        VStack(alignment: .leading, spacing: 7) {
          Text("AUTOMATIC TRACKING")
            .realityEyebrow()
          Text(model.collectorStatus.title)
            .font(.title3.bold())
          Text(model.collectorStatus.detail)
            .foregroundStyle(.secondary)
            .font(.callout)
          Text(
            "Reality records app identity, idle time, and Mac lifecycle signals locally—not content."
          )
          .foregroundStyle(.tertiary)
          .font(.caption)
          .padding(.top, 3)
        }
      }
    }
  }

  private var intentionCard: some View {
    RealityCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("TODAY’S INTENTION")
          .realityEyebrow()
        TextField("Essential outcome", text: $essential)
          .textFieldStyle(.roundedBorder)
        TextField("Optional outcome", text: $optionalOne)
          .textFieldStyle(.roundedBorder)
        TextField("Optional outcome", text: $optionalTwo)
          .textFieldStyle(.roundedBorder)
        Button("Save intention") {
          model.todayStore?.saveIntention(
            essential: essential, optionalOutcomes: [optionalOne, optionalTwo])
          if let store = model.todayStore {
            model.reviewStore?.prepare(summary: store.summary, intention: store.intention)
          }
        }
        .disabled(essential.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
  }

  @ViewBuilder
  private var timelineSection: some View {
    if let store = model.todayStore, !store.blocks.isEmpty {
      TimelineView(store: store)
    } else {
      emptyTimeline
    }
  }

  private var emptyTimeline: some View {
    RealityCard {
      VStack(spacing: 16) {
        Image(systemName: "clock.badge.questionmark")
          .font(.system(size: 42, weight: .light))
          .foregroundStyle(.secondary)
        Text(model.emptyStateMessage)
          .font(.system(size: 24, weight: .semibold, design: .serif))
        Text(
          model.isTracking
            ? "Evidence is being processed into private activity blocks. The daily timeline arrives next."
            : "Start automatic tracking to build a real timeline."
        )
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 480)
      }
      .frame(maxWidth: .infinity, minHeight: 190)
    }
  }

  private var privacyFooter: some View {
    HStack {
      Label("Local-first", systemImage: "internaldrive")
      Spacer()
      Text("Your time is your life in concrete form.")
        .font(.system(.caption, design: .serif).italic())
      Spacer()
      Label("No account", systemImage: "person.crop.circle.badge.xmark")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 4)
  }
}

struct RealityCard<Content: View>: View {
  var tint: Color = .clear
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(22)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(.regularMaterial)
          .overlay(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
          }
      }
  }
}

extension View {
  func realityEyebrow() -> some View {
    font(.caption2.weight(.bold))
      .tracking(1.2)
      .foregroundStyle(.secondary)
  }
}
