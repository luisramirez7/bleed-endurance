import SwiftUI
import BleedCore

/// HealthKit permission ask, led by the privacy promise.
struct OnboardingView: View {
    var connectHealth: () -> Void
    var logManually: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CycleWheelView(
                spans: CycleWheelView.defaultSpans(),
                cycleLength: 28,
                currentDay: 1,
                score: nil,
                scoreLabel: nil,
                currentPhase: .menstrual,
                showsPin: false,
                hubContent: AnyView(
                    Text(Bloom.sparkle)
                        .font(.baloo(32))
                        .foregroundStyle(Bloom.ink)
                )
            )
            .frame(width: 170, height: 170)
            .padding(.top, 36)
            .padding(.bottom, 30)

            Text("Let's get to know your cycle")
                .font(.baloo(27))
                .foregroundStyle(Bloom.ink)
                .multilineTextAlignment(.center)

            Text("Bleed learns your normal for each phase, so a luteal dip never gets mistaken for burnout.")
                .font(.nunito(14, .semiBold))
                .foregroundStyle(Bloom.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)
                .padding(.bottom, 24)

            privacyCard

            Spacer()

            Button(action: connectHealth) {
                Text("Connect Apple Health")
                    .font(.baloo(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Bloom.bloomPurple)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Bloom.bloomPurple.opacity(0.35), radius: 8, y: 6)
            }
            .padding(.top, 20)

            Button(action: logManually) {
                Text("Log my period manually instead")
                    .font(.baloo(14))
                    .foregroundStyle(Bloom.purple600)
                    .padding(.vertical, 13)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .background(Bloom.bgCream)
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("✓")
                .font(.baloo(16))
                .foregroundStyle(Bloom.skyBlue)
                .frame(width: 34, height: 34)
                .background(
                    Bloom.skyBlue.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Your period stays on your phone")
                    .font(.baloo(13))
                    .foregroundStyle(Bloom.ink)
                Text("Flow, symptoms and temperature never leave this device. Only your phase label ever syncs, never the raw data.")
                    .font(.nunito(12, .semiBold))
                    .foregroundStyle(Bloom.inkSoft)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Bloom.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Bloom.cardShadow, radius: 9, y: 6)
    }
}

#Preview {
    OnboardingView(connectHealth: {}, logManually: {})
}
