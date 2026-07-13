import SwiftUI
import BleedCore

/// HRV against the phase-stratified baseline: the luteal band, the flat
/// 60-day average as a dashed line, and 14 days of dots.
struct RecoveryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recovery")
                    .font(.baloo(26))
                    .foregroundStyle(Bloom.ink)
                Text("Last 14 days")
                    .font(.nunito(12, .bold))
                    .foregroundStyle(Bloom.inkMute)
                    .padding(.top, 2)
                    .padding(.bottom, 18)

                hrvCard

                insightCard
                    .padding(.top, 14)

                metricTiles
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Bloom.bgCream)
    }

    private var hrvCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HRV today")
                        .font(.nunito(10, .bold))
                        .kerning(1)
                        .textCase(.uppercase)
                        .foregroundStyle(Bloom.inkMute)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(DemoData.hrvToday))")
                            .font(.baloo(40))
                            .foregroundStyle(Bloom.ink)
                        Text("ms")
                            .font(.nunito(15, .bold))
                            .foregroundStyle(Bloom.inkMute)
                    }
                }
                Spacer()
                BloomChip(
                    text: "On your Wind-down average",
                    color: Bloom.bloomPurple,
                    textColor: Bloom.purple600,
                    uppercased: false
                )
            }

            HRVChart(
                values: DemoData.hrvHistory,
                flatBaseline: DemoData.flatBaselineHRV,
                phaseBand: DemoData.lutealBaselineRange,
                bandColor: Bloom.bloomPurple
            )
            .frame(height: 118)

            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Bloom.bloomPurple.opacity(0.2))
                        .frame(width: 14, height: 8)
                    Text("Your luteal range")
                        .font(.nunito(10, .bold))
                        .foregroundStyle(Bloom.inkMute)
                }
                Spacer()
                HStack(spacing: 6) {
                    DashedLineGlyph()
                        .frame(width: 14, height: 2)
                    Text("Flat 60-day avg")
                        .font(.nunito(10, .bold))
                        .foregroundStyle(Bloom.inkMute)
                }
            }
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
        var text = AttributedString(DemoData.recoveryInsight)
        if let range = text.range(of: "17% low") {
            text[range].foregroundColor = Bloom.flareOrange
            text[range].font = .nunito(13, .extraBold)
        }
        if let range = text.range(of: "luteal average") {
            text[range].foregroundColor = Bloom.bloomPurple
            text[range].font = .nunito(13, .extraBold)
        }
        return text
    }

    private var metricTiles: some View {
        HStack(spacing: 10) {
            MetricTile(label: "Resting HR", value: "\(Int(DemoData.rhrToday))", unit: "bpm", color: Bloom.coralPink)
            MetricTile(label: "Sleep", value: DemoData.sleepToday, unit: nil, color: Bloom.skyBlue)
            MetricTile(label: "Resp rate", value: DemoData.respiratoryRate.formatted(), unit: nil, color: Bloom.amber)
        }
    }
}

/// Labelled tile with a big coloured numeral, used on Recovery and Load.
struct MetricTile: View {
    let label: String
    let value: String
    let unit: String?
    let color: Color
    var caption: String?
    var background: Color = Bloom.surface
    var labelColor: Color = Bloom.inkMute

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.nunito(9, .bold))
                .kerning(0.6)
                .textCase(.uppercase)
                .foregroundStyle(labelColor)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.baloo(24))
                    .foregroundStyle(color)
                if let unit {
                    Text(unit)
                        .font(.nunito(11, .bold))
                        .foregroundStyle(labelColor)
                }
            }
            if let caption {
                Text(caption)
                    .font(.nunito(9, .bold))
                    .foregroundStyle(labelColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DashedLineGlyph: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height / 2))
            path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.stroke(
                path, with: .color(Color(hex: 0xC9B7BF)),
                style: .init(lineWidth: 2, dash: [3, 3])
            )
        }
    }
}

/// The baseline chart: phase band, dashed flat average, round-capped line.
struct HRVChart: View {
    let values: [Double]
    let flatBaseline: Double
    let phaseBand: ClosedRange<Double>
    let bandColor: Color

    private let domain = 40.0...66.0

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 14
            func x(_ i: Int) -> CGFloat {
                inset + CGFloat(i) * (size.width - inset * 2) / CGFloat(values.count - 1)
            }
            func y(_ v: Double) -> CGFloat {
                let t = (v - domain.lowerBound) / (domain.upperBound - domain.lowerBound)
                return size.height - 10 - t * (size.height - 26)
            }

            // Phase band
            let bandRect = CGRect(
                x: 0, y: y(phaseBand.upperBound),
                width: size.width,
                height: y(phaseBand.lowerBound) - y(phaseBand.upperBound)
            )
            context.fill(Path(bandRect), with: .color(bandColor.opacity(0.12)))

            // Flat baseline, dashed
            var flat = Path()
            flat.move(to: CGPoint(x: 0, y: y(flatBaseline)))
            flat.addLine(to: CGPoint(x: size.width, y: y(flatBaseline)))
            context.stroke(
                flat, with: .color(Color(hex: 0xC9B7BF)),
                style: .init(lineWidth: 1.4, dash: [4, 4])
            )

            // The line
            let points = values.indices.map { CGPoint(x: x($0), y: y(values[$0])) }
            var line = Path()
            line.addLines(points)
            context.stroke(
                line, with: .color(bandColor),
                style: .init(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
            )

            // Dots, last one emphasized
            for (i, point) in points.enumerated() {
                let isLast = i == points.count - 1
                let r: CGFloat = isLast ? 5.5 : 3
                let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
                if isLast {
                    context.fill(Circle().path(in: rect), with: .color(bandColor))
                    context.stroke(Circle().path(in: rect), with: .color(.white), lineWidth: 2.5)
                } else {
                    context.fill(Circle().path(in: rect), with: .color(.white))
                    context.stroke(Circle().path(in: rect), with: .color(bandColor), lineWidth: 1.6)
                }
            }
        }
    }
}

#Preview {
    RecoveryView()
}
