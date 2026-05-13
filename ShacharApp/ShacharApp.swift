import SwiftUI
import SwiftData

@main
struct ShacharApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Course.self, StudyTask.self, ScheduleEvent.self])
    }
}
