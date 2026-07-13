import Foundation
import Testing
@testable import BleedCore

struct ReadinessEngineTests {
    let engine = ReadinessEngine()
    let date = Date(timeIntervalSince1970: 1_780_000_000)

    /// Follicular baseline HRV 60, luteal baseline HRV 50: the classic pattern
    /// where luteal HRV runs meaningfully lower than follicular HRV.
    var baseline: UserBaseline {
        UserBaseline(
            byPhase: [
                .follicular: .init(
                    meanHRV: 60, hrvStandardDeviation: 5,
                    meanRestingHeartRate: 50, rhrStandardDeviation: 3, sampleCount: 20
                ),
                .luteal: .init(
                    meanHRV: 50, hrvStandardDeviation: 5,
                    meanRestingHeartRate: 54, rhrStandardDeviation: 3, sampleCount: 20
                ),
            ],
            overall: .init(
                meanHRV: 55, hrvStandardDeviation: 6,
                meanRestingHeartRate: 52, rhrStandardDeviation: 3, sampleCount: 60
            ),
            updatedAt: date
        )
    }

    func recovery(hrv: Double?) -> RecoverySnapshot {
        RecoverySnapshot(
            hrv: hrv, restingHeartRate: 52, sleepDuration: 8 * 3600,
            sleepQuality: 0.8, respiratoryRate: 14, date: date
        )
    }

    func phase(_ phase: CyclePhase) -> CyclePhaseEstimate {
        CyclePhaseEstimate(phase: phase, cycleDay: 22, confidence: 0.9, source: .logged, date: date)
    }

    @Test func lutealDipAtLutealBaselineIsAttributedToPhase() {
        // HRV 49 looks suppressed vs the flat baseline (55) but is normal for luteal (50).
        let result = engine.computeReadiness(.init(
            recovery: recovery(hrv: 49),
            load: TrainingLoadSnapshot(ctl: 70, atl: 75, yesterdayLoad: 80, plannedLoad: 90, date: date),
            phase: phase(.luteal),
            baseline: baseline
        ))
        #expect(result.primaryDriver == .cyclePhase)
        #expect(result.recommendation == .proceed || result.recommendation == .holdPlan)
        #expect(result.phaseAdjustedScore > result.score)
    }

    @Test func sameHRVInFollicularPhaseIsTrainingFatigue() {
        // HRV 49 in the follicular phase is more than 2 SD below the follicular baseline (60).
        let result = engine.computeReadiness(.init(
            recovery: recovery(hrv: 49),
            load: TrainingLoadSnapshot(ctl: 70, atl: 95, yesterdayLoad: 150, plannedLoad: 90, date: date),
            phase: phase(.follicular),
            baseline: baseline
        ))
        #expect(result.primaryDriver == .trainingFatigue)
        #expect(result.recommendation == .rest)
    }

    @Test func aboveBaselineIsRecovered() {
        let result = engine.computeReadiness(.init(
            recovery: recovery(hrv: 62),
            load: nil,
            phase: phase(.follicular),
            baseline: baseline
        ))
        #expect(result.primaryDriver == .recovered)
        #expect(result.recommendation == .proceed)
    }

    @Test func missingHRVYieldsInsufficientData() {
        let result = engine.computeReadiness(.init(
            recovery: recovery(hrv: nil),
            load: nil,
            phase: nil,
            baseline: baseline
        ))
        #expect(result.primaryDriver == .insufficientData)
        #expect(result.confidence <= 0.2)
    }

    @Test func underpoweredPhaseStratumFallsBackToOverallBaseline() {
        let thinBaseline = UserBaseline(
            byPhase: [
                .luteal: .init(
                    meanHRV: 50, hrvStandardDeviation: 5,
                    meanRestingHeartRate: 54, rhrStandardDeviation: 3, sampleCount: 2
                )
            ],
            overall: .init(
                meanHRV: 55, hrvStandardDeviation: 6,
                meanRestingHeartRate: 52, rhrStandardDeviation: 3, sampleCount: 30
            ),
            updatedAt: date
        )
        let result = engine.computeReadiness(.init(
            recovery: recovery(hrv: 49),
            load: nil,
            phase: phase(.luteal),
            baseline: thinBaseline
        ))
        // With only 2 luteal samples the stratum is ignored, so no phase attribution happens.
        #expect(result.phaseAdjustedScore == result.score)
    }
}
