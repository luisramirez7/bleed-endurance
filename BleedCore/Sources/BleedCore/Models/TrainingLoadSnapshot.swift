import Foundation

/// One day's training load state, sourced from intervals.icu (or a future TrainingDataSource).
public struct TrainingLoadSnapshot: Codable, Sendable, Equatable {
    /// Chronic training load (fitness), ~42-day exponentially weighted average of daily load.
    public let ctl: Double
    /// Acute training load (fatigue), ~7-day exponentially weighted average of daily load.
    public let atl: Double
    /// Form / training stress balance: ctl - atl.
    public var form: Double { ctl - atl }
    /// Actual training stress completed yesterday.
    public let yesterdayLoad: Double
    /// Load planned for today, if a plan exists.
    public let plannedLoad: Double?
    public let date: Date

    public init(ctl: Double, atl: Double, yesterdayLoad: Double, plannedLoad: Double?, date: Date) {
        self.ctl = ctl
        self.atl = atl
        self.yesterdayLoad = yesterdayLoad
        self.plannedLoad = plannedLoad
        self.date = date
    }
}
