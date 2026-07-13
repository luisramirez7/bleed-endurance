import Foundation
import HealthKit
import BleedCore

/// All HealthKit access lives here.
///
/// Privacy invariant: reproductive samples (menstrual flow, basal body
/// temperature, symptoms) are read and processed on-device only. No method on
/// this type may return raw reproductive samples to networking code.
actor HealthKitService {
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        [
            HKCategoryType(.menstrualFlow),
            HKQuantityType(.basalBodyTemperature),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.respiratoryRate),
            HKCategoryType(.sleepAnalysis),
        ]
    }

    /// Returns false when HealthKit is unavailable on this device.
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        return true
    }

    /// Dates on which a period started (a flow sample not preceded by flow the day before).
    func periodStartDates(monthsBack: Int) async throws -> [Date] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -monthsBack, to: Date())!
        let samples = try await categorySamples(
            type: HKCategoryType(.menstrualFlow),
            from: start
        )

        let flowDays = Set(
            samples
                .filter { $0.value != HKCategoryValueVaginalBleeding.none.rawValue }
                .map { calendar.startOfDay(for: $0.startDate) }
        )
        return flowDays
            .filter { day in
                let previousDay = calendar.date(byAdding: .day, value: -1, to: day)!
                return !flowDays.contains(previousDay)
            }
            .sorted()
    }

    /// Most recent overnight recovery biometrics.
    func latestRecoverySnapshot() async throws -> RecoverySnapshot {
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -2, to: Date())!

        async let hrv = latestQuantity(
            type: HKQuantityType(.heartRateVariabilitySDNN),
            unit: .secondUnit(with: .milli),
            from: windowStart
        )
        async let rhr = latestQuantity(
            type: HKQuantityType(.restingHeartRate),
            unit: HKUnit.count().unitDivided(by: .minute()),
            from: windowStart
        )
        async let respiratory = latestQuantity(
            type: HKQuantityType(.respiratoryRate),
            unit: HKUnit.count().unitDivided(by: .minute()),
            from: windowStart
        )
        async let sleep = lastNightSleepDuration()

        return try await RecoverySnapshot(
            hrv: hrv,
            restingHeartRate: rhr,
            sleepDuration: sleep,
            sleepQuality: nil,
            respiratoryRate: respiratory,
            date: Date()
        )
    }

    // MARK: - Queries

    private func categorySamples(type: HKCategoryType, from start: Date) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        return try await descriptor.result(for: store)
    }

    private func latestQuantity(type: HKQuantityType, unit: HKUnit, from start: Date) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        return try await descriptor.result(for: store).first?.quantity.doubleValue(for: unit)
    }

    private func lastNightSleepDuration() async throws -> TimeInterval? {
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .hour, value: -24, to: Date())!
        let samples = try await categorySamples(type: HKCategoryType(.sleepAnalysis), from: windowStart)
        let asleep = samples.filter {
            HKCategoryValueSleepAnalysis.allAsleepValues.contains(
                HKCategoryValueSleepAnalysis(rawValue: $0.value) ?? .inBed
            )
        }
        guard !asleep.isEmpty else { return nil }
        return asleep.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }
}
