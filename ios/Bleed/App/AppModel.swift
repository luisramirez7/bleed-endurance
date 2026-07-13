import Foundation
import Observation
import BleedCore

/// Root observable state for the app.
///
/// Orchestrates the on-device pipeline: HealthKit reads -> phase estimation ->
/// readiness computation. Raw reproductive data stays inside this process;
/// only derived phase labels may ever be shared with the backend.
@Observable
@MainActor
final class AppModel {
    enum State {
        case idle
        case loading
        case ready(ReadinessScore, CyclePhaseEstimate?)
        case needsHealthAccess
        case failed(String)
    }

    private(set) var state: State = .idle

    private let healthKit = HealthKitService()
    private let phaseEstimator = CyclePhaseEstimator()
    private let readinessEngine = ReadinessEngine()

    func refresh() async {
        state = .loading
        do {
            guard try await healthKit.requestAuthorization() else {
                state = .needsHealthAccess
                return
            }

            let today = Date()
            let periodStarts = try await healthKit.periodStartDates(monthsBack: 6)
            let phase = phaseEstimator.estimate(periodStartDates: periodStarts, on: today)
            let recovery = try await healthKit.latestRecoverySnapshot()

            // TODO: replace with real phase-stratified baselines computed from history,
            // and merge in intervals.icu load once credentials onboarding exists.
            let baseline = UserBaseline(byPhase: [:], overall: nil, updatedAt: today)

            let score = readinessEngine.computeReadiness(.init(
                recovery: recovery,
                load: nil,
                phase: phase,
                baseline: baseline
            ))
            state = .ready(score, phase)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
