import SwiftUI

/// Onboarding gate, then the four core screens.
struct RootView: View {
    enum Screen: String {
        case today, cycle, recovery, load
    }

    @Environment(AppModel.self) private var model
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    // Launch-argument override (e.g. "-initialTab recovery") for UI verification.
    @State private var selection: Screen =
        Screen(rawValue: UserDefaults.standard.string(forKey: "initialTab") ?? "") ?? .today

    var body: some View {
        if hasOnboarded {
            tabs
        } else {
            OnboardingView(
                connectHealth: {
                    Task {
                        await model.refresh()
                        hasOnboarded = true
                    }
                },
                logManually: {
                    hasOnboarded = true
                }
            )
        }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sparkle", value: .today) {
                TodayView()
            }
            Tab("Cycle", systemImage: "calendar", value: .cycle) {
                CycleCalendarView()
            }
            Tab("Recovery", systemImage: "heart.fill", value: .recovery) {
                RecoveryView()
            }
            Tab("Load", systemImage: "chart.line.uptrend.xyaxis", value: .load) {
                TrainingLoadView()
            }
        }
        .tint(Bloom.bloomPurple)
    }
}

#Preview {
    RootView()
        .environment(AppModel())
}
