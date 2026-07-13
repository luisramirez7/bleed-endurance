import Foundation

/// What is primarily driving today's readiness, shown to the user as the "why".
public enum ReadinessDriver: String, Codable, Sendable {
    /// Recovery deviation is mostly explained by the expected effect of the current cycle phase.
    case cyclePhase
    /// Recovery deviation is mostly unexplained by phase: training or life stress.
    case trainingFatigue
    /// Recovery markers are at or above baseline.
    case recovered
    /// Not enough data to attribute the deviation.
    case insufficientData
}

public enum TrainingRecommendation: String, Codable, Sendable {
    case proceed
    case holdPlan
    case reduceIntensity
    case rest
}

/// The daily output object. The thing users open the app to see.
public struct ReadinessScore: Codable, Sendable, Equatable {
    /// 0...100 readiness ignoring cycle phase context.
    public let score: Double
    /// 0...100 readiness after attributing phase-expected deviation.
    public let phaseAdjustedScore: Double
    public let primaryDriver: ReadinessDriver
    public let recommendation: TrainingRecommendation
    /// 0...1, floor of the confidences of the inputs that produced this score.
    public let confidence: Double
    public let date: Date

    public init(
        score: Double,
        phaseAdjustedScore: Double,
        primaryDriver: ReadinessDriver,
        recommendation: TrainingRecommendation,
        confidence: Double,
        date: Date
    ) {
        self.score = score
        self.phaseAdjustedScore = phaseAdjustedScore
        self.primaryDriver = primaryDriver
        self.recommendation = recommendation
        self.confidence = confidence
        self.date = date
    }
}
