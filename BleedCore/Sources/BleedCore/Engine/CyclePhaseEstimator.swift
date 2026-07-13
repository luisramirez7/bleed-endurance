import Foundation

/// Estimates the current cycle phase from logged period start dates.
///
/// v1 is calendar-based: anchor on the most recent logged period start and
/// personalize phase boundaries with the user's own cycle-length history.
/// Basal/wrist temperature refinement comes later and only ever runs on-device.
public struct CyclePhaseEstimator: Sendable {
    public struct Configuration: Sendable {
        /// Used until the user has enough history to compute their own average.
        public var defaultCycleLength: Int = 28
        public var defaultMenstrualLength: Int = 5
        /// Days around predicted ovulation treated as the ovulatory window.
        public var ovulatoryWindowHalfWidth: Int = 1
        /// Luteal length is more stable across people than follicular length,
        /// so ovulation is anchored backwards from the predicted next period.
        public var lutealLength: Int = 14

        public init() {}
    }

    public let configuration: Configuration
    private let calendar: Calendar

    public init(configuration: Configuration = Configuration(), calendar: Calendar = .current) {
        self.configuration = configuration
        self.calendar = calendar
    }

    /// - Parameters:
    ///   - periodStartDates: user-logged period start dates, any order.
    ///   - date: the day to estimate for.
    /// - Returns: nil when there is no logged period to anchor on.
    public func estimate(periodStartDates: [Date], on date: Date) -> CyclePhaseEstimate? {
        let anchors = periodStartDates
            .map { calendar.startOfDay(for: $0) }
            .filter { $0 <= calendar.startOfDay(for: date) }
            .sorted()
        guard let lastPeriodStart = anchors.last else { return nil }

        let cycleLength = averageCycleLength(from: anchors)
        let day = calendar.dateComponents([.day], from: lastPeriodStart, to: calendar.startOfDay(for: date)).day ?? 0
        let cycleDay = (day % cycleLength) + 1
        let cyclesElapsed = day / cycleLength

        let ovulationDay = max(configuration.defaultMenstrualLength + 2, cycleLength - configuration.lutealLength)
        let phase: CyclePhase
        switch cycleDay {
        case ..<(configuration.defaultMenstrualLength + 1):
            phase = .menstrual
        case ..<(ovulationDay - configuration.ovulatoryWindowHalfWidth):
            phase = .follicular
        case ...(ovulationDay + configuration.ovulatoryWindowHalfWidth):
            phase = .ovulatory
        default:
            phase = .luteal
        }

        // Confidence decays as we extrapolate past the anchored cycle without a new logged period.
        let confidence = max(0.2, 0.95 - 0.25 * Double(cyclesElapsed))
        let source: PhaseEstimateSource = cyclesElapsed == 0 ? .logged : .inferred

        return CyclePhaseEstimate(
            phase: phase,
            cycleDay: cycleDay,
            confidence: confidence,
            source: source,
            date: date
        )
    }

    /// Median of recent observed cycle lengths; falls back to the configured default.
    func averageCycleLength(from sortedAnchors: [Date]) -> Int {
        guard sortedAnchors.count >= 2 else { return configuration.defaultCycleLength }
        let lengths = zip(sortedAnchors.dropFirst(), sortedAnchors)
            .compactMap { calendar.dateComponents([.day], from: $1, to: $0).day }
            .filter { (18...45).contains($0) }  // discard gaps from missed logging
        guard !lengths.isEmpty else { return configuration.defaultCycleLength }
        let sorted = lengths.sorted()
        return sorted[sorted.count / 2]
    }
}
