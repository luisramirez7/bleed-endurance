import SwiftUI
import BleedCore

/// The performance management chart with the cycle's phase bands behind it.
struct TrainingLoadView: View {
    private var ctl: Int { Int(DemoData.ctlHistory.last ?? 0) }
    private var atl: Int { Int(DemoData.atlHistory.last ?? 0) }
    private var form: Int { ctl - atl }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Training load")
                    .font(.baloo(26))
                    .foregroundStyle(Bloom.ink)
                Text("This cycle · from intervals.icu")
                    .font(.nunito(12, .bold))
                    .foregroundStyle(Bloom.inkMute)
                    .padding(.top, 2)
                    .padding(.bottom, 18)

                HStack(spacing: 10) {
                    MetricTile(label: "Fitness", value: "\(ctl)", unit: nil, color: Bloom.bloomPurple, caption: "CTL")
                    MetricTile(label: "Fatigue", value: "\(atl)", unit: nil, color: Bloom.flareOrange, caption: "ATL")
                    MetricTile(
                        label: "Form", value: "\(form)", unit: nil, color: .white,
                        caption: "TSB", background: Bloom.ink, labelColor: .white.opacity(0.6)
                    )
                }
                .padding(.bottom, 14)

                pmcCard

                insightCard
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Bloom.bgCream)
    }

    private var pmcCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            PMCChart(
                ctl: DemoData.ctlHistory,
                atl: DemoData.atlHistory,
                spans: CycleWheelView.defaultSpans()
            )
            .frame(height: 130)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Bloom.bloomPurple.opacity(0.35))
                        .frame(width: 14, height: 8)
                    Text("Fitness")
                        .font(.nunito(10, .bold))
                        .foregroundStyle(Bloom.inkMute)
                }
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Bloom.flareOrange)
                        .frame(width: 14, height: 2)
                    Text("Fatigue")
                        .font(.nunito(10, .bold))
                        .foregroundStyle(Bloom.inkMute)
                }
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Bloom.flareOrange, Bloom.bloomPurple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .opacity(0.4)
                        .frame(width: 10, height: 10)
                    Text("Cycle phase")
                        .font(.nunito(10, .bold))
                        .foregroundStyle(Bloom.inkMute)
                }
            }
            .padding(.horizontal, 4)
        }
        .bloomCard(padding: 16)
    }

    private var insightCard: some View {
        Text(insightText)
            .font(.nunito(13, .semiBold))
            .foregroundStyle(Color(hex: 0x5A4763))
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(Bloom.surfaceLilac)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var insightText: AttributedString {
        var text = AttributedString(DemoData.loadInsight)
        if let range = text.range(of: "form is holding up") {
            text[range].foregroundColor = Bloom.bloomPurple
            text[range].font = .nunito(13, .extraBold)
        }
        return text
    }
}

/// CTL area + line over ATL line, phase-tinted bands behind.
struct PMCChart: View {
    let ctl: [Double]
    let atl: [Double]
    let spans: [CycleWheelView.PhaseSpan]

    private let domain = 30.0...90.0

    var body: some View {
        Canvas { context, size in
            let count = ctl.count
            func x(_ i: Int) -> CGFloat {
                8 + CGFloat(i) * (size.width - 16) / CGFloat(count - 1)
            }
            func y(_ v: Double) -> CGFloat {
                let t = (v - domain.lowerBound) / (domain.upperBound - domain.lowerBound)
                return size.height - 8 - t * (size.height - 20)
            }

            // Phase bands behind everything
            for span in spans {
                let x0 = x(span.dayRange.lowerBound - 1)
                let x1 = x(min(span.dayRange.upperBound, count) - 1)
                context.fill(
                    Path(CGRect(x: x0, y: 0, width: x1 - x0, height: size.height)),
                    with: .color(span.phase.tint)
                )
            }

            // CTL area fill
            let ctlPoints = ctl.indices.map { CGPoint(x: x($0), y: y(ctl[$0])) }
            var area = Path()
            area.move(to: CGPoint(x: x(0), y: size.height - 8))
            area.addLines(ctlPoints)
            area.addLine(to: CGPoint(x: x(count - 1), y: size.height - 8))
            area.closeSubpath()
            context.fill(area, with: .color(Bloom.bloomPurple.opacity(0.22)))

            // CTL line
            var ctlLine = Path()
            ctlLine.addLines(ctlPoints)
            context.stroke(
                ctlLine, with: .color(Bloom.bloomPurple),
                style: .init(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
            )

            // ATL line
            var atlLine = Path()
            atlLine.addLines(atl.indices.map { CGPoint(x: x($0), y: y(atl[$0])) })
            context.stroke(
                atlLine, with: .color(Bloom.flareOrange),
                style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

#Preview {
    TrainingLoadView()
}
