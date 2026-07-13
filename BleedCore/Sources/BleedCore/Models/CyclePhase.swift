import Foundation

/// The four canonical menstrual cycle phases used throughout the app.
///
/// Phase boundaries are estimated, not measured. Every consumer of a phase
/// value must also consider the associated confidence on `CyclePhaseEstimate`.
public enum CyclePhase: String, Codable, Sendable, CaseIterable {
    case menstrual
    case follicular
    case ovulatory
    case luteal
}

/// How a cycle phase estimate was derived.
public enum PhaseEstimateSource: String, Codable, Sendable {
    /// Directly anchored to a user-logged period start (highest confidence near the anchor).
    case logged
    /// Inferred from cycle-length history without a recent logged anchor.
    case inferred
}

/// The on-device output of the cycle phase estimator.
///
/// This is the only cycle-related object that may ever be sent to the backend.
/// Raw reproductive data (flow, basal temperature, symptoms) never leaves the device.
public struct CyclePhaseEstimate: Codable, Sendable, Equatable {
    public let phase: CyclePhase
    /// 1-indexed day within the current cycle.
    public let cycleDay: Int
    /// 0...1. Degrades as distance from the last logged anchor grows.
    public let confidence: Double
    public let source: PhaseEstimateSource
    public let date: Date

    public init(phase: CyclePhase, cycleDay: Int, confidence: Double, source: PhaseEstimateSource, date: Date) {
        self.phase = phase
        self.cycleDay = cycleDay
        self.confidence = confidence
        self.source = source
        self.date = date
    }
}
