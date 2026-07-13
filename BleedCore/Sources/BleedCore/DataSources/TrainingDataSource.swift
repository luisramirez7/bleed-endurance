import Foundation

/// A provider of training load and (optionally) wellness data.
///
/// intervals.icu is the first implementation. Strava and TrainingPeaks are
/// added later by conforming to this protocol; nothing downstream changes.
public protocol TrainingDataSource: Sendable {
    var identifier: String { get }

    /// Daily load snapshots for the given date range, most recent last.
    func trainingLoad(from startDate: Date, to endDate: Date) async throws -> [TrainingLoadSnapshot]

    /// Recovery/wellness snapshots for the given date range, most recent last.
    /// Sources that carry no wellness data return an empty array.
    func recoverySnapshots(from startDate: Date, to endDate: Date) async throws -> [RecoverySnapshot]
}
