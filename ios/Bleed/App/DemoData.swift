import Foundation
import BleedCore

/// The design system's canonical late-luteal scenario: Maya, cycle day 22,
/// HRV visibly down against a flat average but dead normal for her luteal
/// baseline. Raw score 61, phase-adjusted 82.
///
/// Screens render from this until the real HealthKit + intervals.icu
/// pipelines produce enough history; it is also what previews use.
enum DemoData {
    static let userName = "Maya"
    static let cycleDay = 22
    static let cycleLength = 28

    static let phase = CyclePhaseEstimate(
        phase: .luteal,
        cycleDay: cycleDay,
        confidence: 0.9,
        source: .logged,
        date: .now
    )

    static let score = ReadinessScore(
        score: 61,
        phaseAdjustedScore: 82,
        primaryDriver: .cyclePhase,
        recommendation: .reduceIntensity,
        confidence: 0.9,
        date: .now
    )

    static let recommendationTitle = "Ease off today, superstar \(Bloom.sparkle)"
    static let recommendationBody =
        "Your HRV's a little low, but that's just your luteal phase talking, not fatigue. Keep it light and you'll bounce right back."

    // Recovery
    static let hrvToday = 48.0
    static let rhrToday = 54.0
    static let sleepToday = "7:20"
    static let respiratoryRate = 15.2
    /// Last 14 days of HRV, oldest first.
    static let hrvHistory: [Double] = [63, 61, 58, 55, 53, 50, 49, 51, 48, 47, 49, 50, 49, 48]
    static let flatBaselineHRV = 58.0
    static let lutealBaselineRange = 46.0...52.0
    static let recoveryInsight =
        "Against a flat average your HRV looks 17% low. Against your luteal average, it's dead normal. That gap is the whole point of Bleed."

    // Training load (one cycle of daily values, oldest first)
    static let ctlHistory: [Double] = [
        44, 45, 46, 47, 48, 50, 51, 52, 54, 55, 56, 58, 59, 60,
        61, 62, 63, 64, 64, 65, 65, 66, 66, 65, 64, 64, 63, 63,
    ]
    static let atlHistory: [Double] = [
        50, 62, 58, 70, 66, 55, 48, 72, 80, 68, 60, 52, 75, 82,
        70, 62, 54, 78, 74, 66, 58, 50, 60, 72, 64, 56, 50, 52,
    ]
    static let loadInsight =
        "You're carrying real fatigue, but your form is holding up. Paired with an expected luteal dip, that's a \"hold, don't hammer\" day, not a rest day."

    // Calendar: 5 weeks around July 2026, the same scenario.
    struct CalendarDay {
        let label: String
        let phase: CyclePhase
        let readiness: Double
        let isMuted: Bool
        let isToday: Bool
    }

    static let calendarTitle = "July 2026"
    static let calendarSubtitle = "Cycle day 22 · next bleed in 7 days"

    static let calendarWeeks: [[CalendarDay]] = {
        // (label, phase, readiness, muted, today)
        let raw: [(String, CyclePhase, Double, Bool, Bool)] = [
            ("28", .follicular, 74, true, false), ("29", .follicular, 77, true, false),
            ("30", .follicular, 80, true, false), ("1", .follicular, 82, false, false),
            ("2", .follicular, 79, false, false), ("3", .follicular, 83, false, false),
            ("4", .ovulatory, 85, false, false),
            ("5", .ovulatory, 84, false, false), ("6", .ovulatory, 80, false, false),
            ("7", .luteal, 72, false, false), ("8", .luteal, 68, false, false),
            ("9", .luteal, 64, false, false), ("10", .luteal, 66, false, false),
            ("11", .luteal, 63, false, false),
            ("12", .luteal, 65, false, false), ("13", .luteal, 82, false, true),
            ("14", .luteal, 63, false, false), ("15", .luteal, 60, false, false),
            ("16", .luteal, 64, false, false), ("17", .luteal, 69, false, false),
            ("18", .luteal, 71, false, false),
            ("19", .luteal, 70, false, false), ("20", .menstrual, 55, false, false),
            ("21", .menstrual, 52, false, false), ("22", .menstrual, 58, false, false),
            ("23", .menstrual, 62, false, false), ("24", .menstrual, 66, false, false),
            ("25", .follicular, 78, false, false),
            ("26", .follicular, 80, false, false), ("27", .follicular, 83, false, false),
            ("28", .follicular, 85, false, false), ("29", .follicular, 82, false, false),
            ("30", .follicular, 84, false, false), ("31", .follicular, 86, true, false),
            ("1", .follicular, 84, true, false),
        ]
        return stride(from: 0, to: raw.count, by: 7).map { start in
            raw[start..<min(start + 7, raw.count)].map {
                CalendarDay(label: $0.0, phase: $0.1, readiness: $0.2, isMuted: $0.3, isToday: $0.4)
            }
        }
    }()
}

/// Playful hub label for a readiness score.
func readinessLabel(for score: Double) -> String {
    switch score {
    case 85...: "Ready"
    case 70..<85: "Ready-ish"
    case 50..<70: "Take it easy"
    default: "Rest up"
    }
}
