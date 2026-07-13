import SwiftUI

@main
struct BleedApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environment(appModel)
        }
    }
}
