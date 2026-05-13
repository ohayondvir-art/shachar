import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("בית", systemImage: "house.fill") }

            TasksView()
                .tabItem { Label("מטלות", systemImage: "checklist") }

            ScheduleView()
                .tabItem { Label("לוז", systemImage: "calendar") }

            CoursesView()
                .tabItem { Label("קורסים", systemImage: "book.fill") }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
