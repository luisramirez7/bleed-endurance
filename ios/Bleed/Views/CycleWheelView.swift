import SwiftUI
import BleedCore

/// Bloom's signature object: a donut split into the four phases sized by
/// their real length, a "you are here" pin on today, and the readiness
/// score in the hub. The pin spins in like a wheel of fortune on appear.
struct CycleWheelView: View {
    struct PhaseSpan: Identifiable {
        let phase: CyclePhase
        let dayRange: ClosedRange<Int>
        var id: String { phase.rawValue }
    }

    let spans: [PhaseSpan]
    let cycleLength: Int
    let currentDay: Int
    let score: Int?
    let scoreLabel: String?
    let currentPhase: CyclePhase
    var showsPin = true
    var hubContent: AnyView?

    @State private var pinAngle: Angle = .degrees(-260)
    @State private var tagVisible = false

    /// Standard 28-day spans matching CyclePhaseEstimator's default boundaries.
    static func defaultSpans() -> [PhaseSpan] {
        [
            .init(phase: .menstrual, dayRange: 1...5),
            .init(phase: .follicular, dayRange: 6...12),
            .init(phase: .ovulatory, dayRange: 13...15),
            .init(phase: .luteal, dayRange: 16...28),
        ]
    }

    private func fraction(of day: Double) -> Double {
        day / Double(cycleLength)
    }

    private var targetPinAngle: Angle {
        .degrees(fraction(of: Double(currentDay) - 0.5) * 360)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let ringWidth = side * 0.1
            let radius = side * 0.35
            let gapDegrees = 6.0

            ZStack {
                ForEach(spans) { span in
                    let start = fraction(of: Double(span.dayRange.lowerBound - 1)) * 360
                    let end = fraction(of: Double(span.dayRange.upperBound)) * 360
                    Circle()
                        .trim(
                            from: (start + gapDegrees / 2) / 360,
                            to: (end - gapDegrees / 2) / 360
                        )
                        .stroke(
                            span.phase.color,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: radius * 2, height: radius * 2)
                }

                hub
                    .frame(maxWidth: (radius - ringWidth / 2) * 2 - 8)

                if showsPin {
                    pin(radius: radius, side: side)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard showsPin else { return }
            withAnimation(.spring(response: 1.15, dampingFraction: 0.72)) {
                pinAngle = targetPinAngle
            }
            withAnimation(.easeOut(duration: 0.35).delay(0.9)) {
                tagVisible = true
            }
        }
    }

    private var hub: some View {
        Group {
            if let hubContent {
                hubContent
            } else {
                VStack(spacing: 1) {
                    if let scoreLabel {
                        Text(scoreLabel)
                            .font(.nunito(10, .bold))
                            .kerning(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(Bloom.inkMute)
                    }
                    if let score {
                        Text("\(score)")
                            .font(.baloo(60))
                            .foregroundStyle(Bloom.ink)
                            .padding(.bottom, -6)
                    }
                    BloomChip(
                        text: "\(currentPhase.nickname) · Day \(currentDay)",
                        color: currentPhase.color,
                        textColor: currentPhase.textColor
                    )
                    .padding(.top, 4)
                }
            }
        }
    }

    private func pin(radius: CGFloat, side: CGFloat) -> some View {
        ZStack {
            // The dot, riding the ring.
            Circle()
                .fill(.white)
                .stroke(currentPhase.color, lineWidth: 4)
                .background(
                    Circle()
                        .stroke(currentPhase.color.opacity(0.22), lineWidth: 5)
                        .padding(-5)
                )
                .frame(width: side * 0.09, height: side * 0.09)
                .shadow(color: .black.opacity(0.22), radius: 4, y: 3)
                .offset(y: -radius)

            // The tag, floating above the dot, kept upright.
            Text("YOU ARE HERE")
                .font(.baloo(9))
                .kerning(0.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    currentPhase.color,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .shadow(color: currentPhase.color.opacity(0.4), radius: 5, y: 4)
                .rotationEffect(-pinAngle)
                .offset(y: -radius - side * 0.17)
                .opacity(tagVisible ? 1 : 0)
                .scaleEffect(tagVisible ? 1 : 0.5)
        }
        .rotationEffect(pinAngle)
    }
}
