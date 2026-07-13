import SwiftUI
import BleedCore

/// The one screen that matters: today's readiness and the why.
struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .idle, .loading:
                    ProgressView("Computing readiness…")
                case .needsHealthAccess:
                    ContentUnavailableView(
                        "Health access needed",
                        systemImage: "heart.text.square",
                        description: Text("Bleed needs permission to read your cycle and recovery data. Everything reproductive stays on this device.")
                    )
                case .failed(let message):
                    ContentUnavailableView(
                        "Something went wrong",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                case .ready(let score, let phase):
                    readinessContent(score: score, phase: phase)
                }
            }
            .navigationTitle("Today")
        }
        .task { await model.refresh() }
    }

    private func readinessContent(score: ReadinessScore, phase: CyclePhaseEstimate?) -> some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text("\(Int(score.phaseAdjustedScore))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                    Text(recommendationLabel(score.recommendation))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Why") {
                LabeledContent("Primary driver", value: driverLabel(score.primaryDriver))
                if let phase {
                    LabeledContent("Cycle phase", value: "\(phase.phase.rawValue.capitalized), day \(phase.cycleDay)")
                    LabeledContent("Phase confidence", value: phase.confidence.formatted(.percent.precision(.fractionLength(0))))
                }
                LabeledContent("Unadjusted score", value: "\(Int(score.score))")
            }
        }
    }

    private func recommendationLabel(_ recommendation: TrainingRecommendation) -> String {
        switch recommendation {
        case .proceed: "Train as planned"
        case .holdPlan: "Hold the plan, monitor"
        case .reduceIntensity: "Reduce intensity today"
        case .rest: "Rest day"
        }
    }

    private func driverLabel(_ driver: ReadinessDriver) -> String {
        switch driver {
        case .cyclePhase: "Expected cycle phase effect"
        case .trainingFatigue: "Training fatigue"
        case .recovered: "Recovered"
        case .insufficientData: "Not enough data yet"
        }
    }
}
