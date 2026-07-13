import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// intervals.icu API client. First concrete `TrainingDataSource`.
///
/// Auth is HTTP Basic with username "API_KEY" and the athlete's personal key
/// as the password. The key is stored in the Keychain by the app layer and
/// injected here; this type never persists credentials.
public struct IntervalsICUClient: TrainingDataSource {
    public let identifier = "intervals.icu"

    private let athleteId: String
    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://intervals.icu/api/v1")!

    public init(athleteId: String, apiKey: String, session: URLSession = .shared) {
        self.athleteId = athleteId
        self.apiKey = apiKey
        self.session = session
    }

    public func trainingLoad(from startDate: Date, to endDate: Date) async throws -> [TrainingLoadSnapshot] {
        let records = try await wellnessRecords(from: startDate, to: endDate)
        return records.compactMap { record in
            guard let ctl = record.ctl, let atl = record.atl, let date = record.date else { return nil }
            // TODO(field-mapping): populate yesterdayLoad and plannedLoad from the
            // activities/events endpoints once the ingestion contract is finalized.
            return TrainingLoadSnapshot(
                ctl: ctl,
                atl: atl,
                yesterdayLoad: 0,
                plannedLoad: nil,
                date: date
            )
        }
    }

    public func recoverySnapshots(from startDate: Date, to endDate: Date) async throws -> [RecoverySnapshot] {
        let records = try await wellnessRecords(from: startDate, to: endDate)
        return records.compactMap { record in
            guard let date = record.date else { return nil }
            return RecoverySnapshot(
                hrv: record.hrv,
                restingHeartRate: record.restingHR,
                sleepDuration: record.sleepSecs,
                sleepQuality: record.sleepQuality.map { $0 / 4.0 },  // intervals.icu quality is 1...4
                respiratoryRate: record.respiration,
                date: date
            )
        }
    }

    // MARK: - Wire types

    /// Subset of the intervals.icu wellness record. Everything optional: the
    /// API omits fields the athlete has never recorded.
    struct WellnessRecord: Decodable {
        /// ISO local date, e.g. "2026-07-13".
        let id: String
        let ctl: Double?
        let atl: Double?
        let hrv: Double?
        let restingHR: Double?
        let sleepSecs: Double?
        let sleepQuality: Double?
        let respiration: Double?

        var date: Date? {
            Self.dayFormatter.date(from: id)
        }

        static let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
    }

    func wellnessRecords(from startDate: Date, to endDate: Date) async throws -> [WellnessRecord] {
        var components = URLComponents(
            url: baseURL.appending(path: "athlete/\(athleteId)/wellness"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "oldest", value: WellnessRecord.dayFormatter.string(from: startDate)),
            URLQueryItem(name: "newest", value: WellnessRecord.dayFormatter.string(from: endDate)),
        ]

        var request = URLRequest(url: components.url!)
        let credentials = Data("API_KEY:\(apiKey)".utf8).base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw IntervalsICUError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw IntervalsICUError.httpError(statusCode: http.statusCode)
        }
        return try JSONDecoder().decode([WellnessRecord].self, from: data)
    }
}

public enum IntervalsICUError: Error, Sendable {
    case invalidResponse
    case httpError(statusCode: Int)
}
