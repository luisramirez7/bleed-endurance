import Foundation
import Testing
@testable import BleedCore

struct CyclePhaseEstimatorTests {
    let estimator = CyclePhaseEstimator()
    let calendar = Calendar.current

    func day(_ offset: Int, from anchor: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: anchor)!
    }

    var anchor: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
    }

    @Test func noLoggedPeriodsReturnsNil() {
        #expect(estimator.estimate(periodStartDates: [], on: anchor) == nil)
    }

    @Test func dayOneIsMenstrual() throws {
        let estimate = try #require(estimator.estimate(periodStartDates: [anchor], on: anchor))
        #expect(estimate.phase == .menstrual)
        #expect(estimate.cycleDay == 1)
        #expect(estimate.source == .logged)
    }

    @Test func dayTenIsFollicular() throws {
        let estimate = try #require(estimator.estimate(periodStartDates: [anchor], on: day(9, from: anchor)))
        #expect(estimate.phase == .follicular)
        #expect(estimate.cycleDay == 10)
    }

    @Test func dayFourteenIsOvulatoryOnDefaultCycle() throws {
        let estimate = try #require(estimator.estimate(periodStartDates: [anchor], on: day(13, from: anchor)))
        #expect(estimate.phase == .ovulatory)
    }

    @Test func dayTwentyFiveIsLuteal() throws {
        let estimate = try #require(estimator.estimate(periodStartDates: [anchor], on: day(24, from: anchor)))
        #expect(estimate.phase == .luteal)
        #expect(estimate.cycleDay == 25)
    }

    @Test func extrapolatingPastAnchoredCycleLowersConfidence() throws {
        let anchored = try #require(estimator.estimate(periodStartDates: [anchor], on: day(10, from: anchor)))
        let extrapolated = try #require(estimator.estimate(periodStartDates: [anchor], on: day(40, from: anchor)))
        #expect(extrapolated.confidence < anchored.confidence)
        #expect(extrapolated.source == .inferred)
    }

    @Test func personalCycleLengthComesFromHistory() throws {
        // Three cycles of 30 days each.
        let starts = [day(-60, from: anchor), day(-30, from: anchor), anchor]
        #expect(estimator.averageCycleLength(from: starts.sorted()) == 30)
    }

    @Test func implausibleGapsFromMissedLoggingAreIgnored() throws {
        // A 90-day gap (missed logging) must not drag the average.
        let starts = [day(-118, from: anchor), day(-28, from: anchor), anchor]
        #expect(estimator.averageCycleLength(from: starts.sorted()) == 28)
    }

    @Test func futureAnchorsAreIgnored() throws {
        let estimate = try #require(
            estimator.estimate(periodStartDates: [anchor, day(20, from: anchor)], on: day(5, from: anchor))
        )
        #expect(estimate.cycleDay == 6)
    }
}
