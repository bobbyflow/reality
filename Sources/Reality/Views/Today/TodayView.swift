import SwiftUI

struct TodayView: View {
  @Bindable var model: AppModel

  private var dateLabel: String {
    Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        header
        truthGrid
        emptyTimeline
        tomorrowCard
        privacyFooter
      }
      .frame(maxWidth: 1_050, alignment: .leading)
      .padding(32)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .navigationTitle("Today")
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
            "The collector is built in Phase 3. Until then, Reality will never claim it is watching your activity."
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
        Text("Nothing set yet")
          .font(.title3.bold())
        Text("Intentions arrive with durable local storage. The empty state is deliberate.")
          .foregroundStyle(.secondary)
          .font(.callout)
        Spacer(minLength: 0)
        Label("No fabricated goal", systemImage: "checkmark.shield")
          .font(.caption.weight(.semibold))
          .foregroundStyle(Color(red: 0.09, green: 0.52, blue: 0.42))
      }
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
          "Once the local collector is connected, your real timeline will build here automatically."
        )
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 480)
      }
      .frame(maxWidth: .infinity, minHeight: 190)
    }
  }

  private var tomorrowCard: some View {
    RealityCard(tint: Color(red: 0.09, green: 0.52, blue: 0.42).opacity(0.1)) {
      HStack(spacing: 16) {
        Image(systemName: "arrow.forward.circle")
          .font(.title)
          .foregroundStyle(Color(red: 0.09, green: 0.52, blue: 0.42))
        VStack(alignment: .leading, spacing: 5) {
          Text("ONE CORRECTION FOR TOMORROW")
            .realityEyebrow()
          Text("Waiting for a real day to review.")
            .font(.headline)
          Text("Reality recommends nothing until it has trustworthy evidence.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
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

private struct RealityCard<Content: View>: View {
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
  fileprivate func realityEyebrow() -> some View {
    font(.caption2.weight(.bold))
      .tracking(1.2)
      .foregroundStyle(.secondary)
  }
}
