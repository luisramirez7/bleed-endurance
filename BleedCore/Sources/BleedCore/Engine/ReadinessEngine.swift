import Foundation

/// The fusion engine. Rules-based v1.
///
/// The job is disambiguation: how much of today's recovery deviation is the
/// expected effect of the current cycle phase, and how much is residual
/// (training or life stress)? The recommendation keys off the residual.
public struct ReadinessEngine: Sendable {
    public struct Inputs: Sendable {
        public let recovery: RecoverySnapshot
        public let load: TrainingLoadSnapshot?
        public let phase: CyclePhaseEstimate?
        public let baseline: UserBaseline

        public init(
            recovery: RecoverySnapshot,
            load: TrainingLoadSnapshot?,
            phase: CyclePhaseEstimate?,
            baseline: UserBaseline
        ) {
            self.recovery = recovery
            self.load = load
            self.phase = phase
            self.baseline = baseline
        }
    }

    public init() {}

    public func computeReadiness(_ inputs: Inputs) -> ReadinessScore {
        guard let hrv = inputs.recovery.hrv, let overall = inputs.baseline.overall else {
            return ReadinessScore(
                score: 50,
                phaseAdjustedScore: 50,
                primaryDriver: .insufficientData,
                recommendation: .holdPlan,
                confidence: 0.2,
                date: inputs.recovery.date
            )
        }

        // Raw deviation: today's HRV in z-score units against the flat baseline.
        let rawZ = zScore(value: hrv, mean: overall.meanHRV, sd: overall.hrvStandardDeviation)

        // Phase-adjusted deviation: the same value against the phase stratum.
        // The difference between the two is the phase-explained component.
        var phaseZ = rawZ
        var phaseConfidence = 1.0
        if let phase = inputs.phase, let stratum = inputs.baseline.byPhase[phase.phase],
           stratum.sampleCount >= UserBaseline.minimumSamplesPerPhase {
            phaseZ = zScore(value: hrv, mean: stratum.meanHRV, sd: stratum.hrvStandardDeviation)
            phaseConfidence = phase.confidence
        }

        let score = scoreFromZ(rawZ)
        let phaseAdjustedScore = scoreFromZ(phaseZ)

        let driver = attributeDriver(rawZ: rawZ, residualZ: phaseZ)
        let recommendation = recommend(residualZ: phaseZ, form: inputs.load?.form)

        let confidence = min(
            phaseConfidence,
            overall.sampleCount >= 14 ? 0.9 : 0.5
        )

        return ReadinessScore(
            score: score,
            phaseAdjustedScore: phaseAdjustedScore,
            primaryDriver: driver,
            recommendation: recommendation,
            confidence: confidence,
            date: inputs.recovery.date
        )
    }

    // MARK: - Rules

    private func zScore(value: Double, mean: Double, sd: Double) -> Double {
        guard sd > 0 else { return 0 }
        return (value - mean) / sd
    }

    /// Maps a z-score to 0...100 with 50 at baseline, saturating around ±2.5 SD.
    private func scoreFromZ(_ z: Double) -> Double {
        let clamped = min(max(z, -2.5), 2.5)
        return (50 + clamped * 20).rounded()
    }

    private func attributeDriver(rawZ: Double, residualZ: Double) -> ReadinessDriver {
        if residualZ >= -0.5 {
            // After phase adjustment there is no meaningful suppression.
            return rawZ < -0.5 ? .cyclePhase : .recovered
        }
        return .trainingFatigue
    }

    private func recommend(residualZ: Double, form: Double?) -> TrainingRecommendation {
        let deepFatigue = (form ?? 0) < -20
        switch residualZ {
        case ..<(-1.5):
            return .rest
        case ..<(-0.75):
            return deepFatigue ? .rest : .reduceIntensity
        case ..<(-0.25):
            return deepFatigue ? .reduceIntensity : .holdPlan
        default:
            return .proceed
        }
    }
}
