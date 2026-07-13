import Foundation

/// One day's recovery biometrics, from HealthKit and/or intervals.icu wellness data.
public struct RecoverySnapshot: Codable, Sendable, Equatable {
    /// Overnight HRV in milliseconds (rMSSD or SDNN depending on source; keep sources consistent per user).
    public let hrv: Double?
    /// Resting heart rate in beats per minute.
    public let restingHeartRate: Double?
    /// Total sleep duration in seconds.
    public let sleepDuration: TimeInterval?
    /// Source-specific sleep quality score normalized to 0...1, if available.
    public let sleepQuality: Double?
    /// Breaths per minute during sleep.
    public let respiratoryRate: Double?
    public let date: Date

    public init(
        hrv: Double?,
        restingHeartRate: Double?,
        sleepDuration: TimeInterval?,
        sleepQuality: Double?,
        respiratoryRate: Double?,
        date: Date
    ) {
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.respiratoryRate = respiratoryRate
        self.date = date
    }
}
