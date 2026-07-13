import SwiftUI
import BleedCore

/// The hero screen: cycle wheel front and centre, the recommendation, and
/// the numbers behind it. Never hides the unadjusted score; the gap between
/// raw and phase-adjusted is the product's whole argument.
struct TodayView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                CycleWheelView(
                    spans: CycleWheelView.defaultSpans(),
                    cycleLength: DemoData.cycleLength,
                    currentDay: DemoData.cycleDay,
                    score: Int(DemoData.score.phaseAdjustedScore),
                    scoreLabel: readinessLabel(for: DemoData.score.phaseAdjustedScore),
                    currentPhase: DemoData.phase.phase
                )
                .frame(width: 260, height: 260)
                .padding(.top, 20)

                legend
                    .padding(.top, 2)
                    .padding(.bottom, 20)

                recommendationCard

                statTiles
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Bloom.bgCream)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) \(Bloom.sparkle)")
                    .font(.nunito(13, .bold))
                    .foregroundStyle(Bloom.inkMute)
                Text("Hey, \(DemoData.userName)")
                    .font(.baloo(30))
                    .foregroundStyle(Bloom.ink)
            }
            Spacer()
            Text(String(DemoData.userName.prefix(1)))
                .font(.baloo(16))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [Bloom.coralPink, Bloom.bloomPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
        }
    }

    private var legend: some View {
        HStack(spacing: 13) {
            ForEach(CyclePhase.allCases, id: \.self) { phase in
                HStack(spacing: 5) {
                    Circle().fill(phase.color).frame(width: 8, height: 8)
                    Text(phase.nickname)
                        .font(.nunito(10, .bold))
                        .foregroundStyle(
                            phase == DemoData.phase.phase ? phase.textColor : Bloom.inkMute
                        )
                }
            }
        }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(DemoData.recommendationTitle)
                .font(.baloo(14))
                .foregroundStyle(Bloom.purple600)
            Text(DemoData.recommendationBody)
                .font(.nunito(13.5, .semiBold))
                .foregroundStyle(Bloom.inkSoft)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bloomCard()
    }

    private var statTiles: some View {
        HStack(spacing: 9) {
            StatTile(value: "\(Int(DemoData.score.score))", label: "Unadj", color: Bloom.amber)
            StatTile(value: "\(Int(DemoData.hrvToday))", label: "HRV", color: Bloom.bloomPurple)
            StatTile(value: "\(Int(DemoData.rhrToday))", label: "RHR", color: Bloom.coralPink)
            StatTile(value: DemoData.sleepToday, label: "Sleep", color: Bloom.skyBlue)
        }
    }
}

/// Small numeric tile: big Baloo numeral, tiny tracked uppercase label.
struct StatTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.baloo(22))
                .foregroundStyle(color)
            Text(label)
                .font(.nunito(9, .bold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Bloom.inkMute)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Bloom.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    TodayView()
}
