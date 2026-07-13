import Foundation

/// Rolling recovery baselines stratified by cycle phase.
///
/// This is the core differentiator: today's HRV is compared to the user's
/// typical HRV *for the current phase*, not to a flat all-days mean. A luteal
/// HRV dip versus the luteal baseline is neutral; the same absolute value
/// versus the follicular baseline would look alarming.
public struct UserBaseline: Codable, Sendable, Equatable {
    public struct PhaseStatistics: Codable, Sendable, Equatable {
        public let meanHRV: Double
        public let hrvStandardDeviation: Double
        public let meanRestingHeartRate: Double
        public let rhrStandardDeviation: Double
        /// Number of days contributing to these statistics.
        public let sampleCount: Int

        public init(
            meanHRV: Double,
            hrvStandardDeviation: Double,
            meanRestingHeartRate: Double,
            rhrStandardDeviation: Double,
            sampleCount: Int
        ) {
            self.meanHRV = meanHRV
            self.hrvStandardDeviation = hrvStandardDeviation
            self.meanRestingHeartRate = meanRestingHeartRate
            self.rhrStandardDeviation = rhrStandardDeviation
            self.sampleCount = sampleCount
        }
    }

    public let byPhase: [CyclePhase: PhaseStatistics]
    /// Flat baseline across all phases, used as fallback while phase strata are underpowered.
    public let overall: PhaseStatistics?
    public let updatedAt: Date

    public init(byPhase: [CyclePhase: PhaseStatistics], overall: PhaseStatistics?, updatedAt: Date) {
        self.byPhase = byPhase
        self.overall = overall
        self.updatedAt = updatedAt
    }

    /// Minimum days per phase before a stratum is trusted over the overall baseline.
    public static let minimumSamplesPerPhase = 5

    /// Returns the phase stratum when it has enough samples, otherwise the overall baseline.
    public func statistics(for phase: CyclePhase) -> PhaseStatistics? {
        if let stratum = byPhase[phase], stratum.sampleCount >= Self.minimumSamplesPerPhase {
            return stratum
        }
        return overall
    }
}
