import SwiftUI
import BleedCore

/// Month view where cell colour is the cycle phase and a superimposed
/// round-capped line is daily readiness, dots haloed in white so they
/// read over the tinted cells.
struct CycleCalendarView: View {
    private let weeks = DemoData.calendarWeeks

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                weekdayRow
                    .padding(.top, 16)
                    .padding(.bottom, 6)

                VStack(spacing: 2) {
                    ForEach(weeks.indices, id: \.self) { index in
                        WeekRow(days: weeks[index])
                    }
                }

                explainerCard
                    .padding(.top, 22)

                legend
                    .padding(.top, 12)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Bloom.bgCream)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(DemoData.calendarTitle)
                    .font(.baloo(26))
                    .foregroundStyle(Bloom.ink)
                Spacer()
                HStack(spacing: 8) {
                    MonthArrow(symbol: "chevron.left")
                    MonthArrow(symbol: "chevron.right")
                }
            }
            Text(DemoData.calendarSubtitle)
                .font(.nunito(12, .bold))
                .foregroundStyle(Bloom.inkMute)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 2) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"].indices, id: \.self) { i in
                Text(["S", "M", "T", "W", "T", "F", "S"][i])
                    .font(.nunito(10, .extraBold))
                    .foregroundStyle(Bloom.ink.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var explainerCard: some View {
        HStack(spacing: 8) {
            miniLineGlyph
            Text("The line is your daily readiness. Cell colour is your phase.")
                .font(.nunito(12, .bold))
                .foregroundStyle(Bloom.inkSoft)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Bloom.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Bloom.ink.opacity(0.06), radius: 7, y: 4)
    }

    private var miniLineGlyph: some View {
        Canvas { context, _ in
            var path = Path()
            path.move(to: CGPoint(x: 1, y: 12))
            path.addLine(to: CGPoint(x: 8, y: 5))
            path.addLine(to: CGPoint(x: 15, y: 9))
            path.addLine(to: CGPoint(x: 22, y: 3))
            path.addLine(to: CGPoint(x: 33, y: 7))
            context.stroke(path, with: .color(Bloom.ink), style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
            let dot = CGRect(x: 5, y: 2, width: 6, height: 6)
            context.fill(Circle().path(in: dot), with: .color(Bloom.bloomPurple))
            context.stroke(Circle().path(in: dot), with: .color(.white), lineWidth: 1.3)
        }
        .frame(width: 34, height: 16)
    }

    private var legend: some View {
        HStack {
            ForEach(CyclePhase.allCases, id: \.self) { phase in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(phase.tint)
                        .stroke(phase.color, lineWidth: 1.5)
                        .frame(width: 9, height: 9)
                    Text(phase.nickname)
                        .font(.nunito(10, .bold))
                        .foregroundStyle(phase == .luteal ? phase.textColor : Bloom.inkMute)
                }
                if phase != .luteal { Spacer() }
            }
        }
    }
}

private struct MonthArrow: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(Bloom.bloomPurple)
            .frame(width: 30, height: 30)
            .background(Bloom.surface, in: Circle())
            .shadow(color: Bloom.ink.opacity(0.08), radius: 3, y: 2)
    }
}

/// One week: seven tinted cells with the readiness polyline drawn over them.
private struct WeekRow: View {
    let days: [DemoData.CalendarDay]

    private let rowHeight: CGFloat = 58

    private func y(for readiness: Double) -> CGFloat {
        let t = min(max((readiness - 50) / 35, 0), 1)
        return 52 - t * 28
    }

    var body: some View {
        ZStack {
            HStack(spacing: 2) {
                ForEach(days.indices, id: \.self) { i in
                    let day = days[i]
                    VStack {
                        Text(day.label)
                            .font(.baloo(12))
                            .foregroundStyle(day.isToday ? Bloom.ink : day.phase.color)
                            .padding(.top, 6)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(day.phase.tint)
                    .opacity(day.isMuted ? 0.4 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: day.isToday ? 12 : 8, style: .continuous))
                    .overlay {
                        if day.isToday {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Bloom.ink, lineWidth: 2)
                        }
                    }
                }
            }

            Canvas { context, size in
                let cellWidth = (size.width - 12) / 7 + 12.0 / 7
                let points = days.indices.map { i in
                    CGPoint(
                        x: CGFloat(i) * cellWidth + cellWidth / 2,
                        y: y(for: days[i].readiness)
                    )
                }
                var line = Path()
                line.addLines(points)
                context.stroke(
                    line, with: .color(.white.opacity(0.65)),
                    style: .init(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    line, with: .color(Bloom.ink),
                    style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                for (i, point) in points.enumerated() {
                    let rect = CGRect(x: point.x - 3.3, y: point.y - 3.3, width: 6.6, height: 6.6)
                    context.fill(Circle().path(in: rect), with: .color(days[i].phase.color))
                    context.stroke(Circle().path(in: rect), with: .color(.white), lineWidth: 1.4)
                }
            }
            .allowsHitTesting(false)
        }
        .frame(height: rowHeight)
    }
}

#Preview {
    CycleCalendarView()
}
