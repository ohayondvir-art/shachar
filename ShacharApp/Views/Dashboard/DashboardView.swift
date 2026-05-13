import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<StudyTask> { $0.isCompleted == false },
           sort: \StudyTask.dueDate)
    private var pendingTasks: [StudyTask]

    @Query(sort: \ScheduleEvent.startDate)
    private var events: [ScheduleEvent]

    private var upcomingTasks: [StudyTask] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        return Array(pendingTasks.filter { $0.dueDate <= cutoff }.prefix(5))
    }

    private var nextEvent: ScheduleEvent? {
        events.first { $0.startDate >= Date() }
    }

    private var eventsThisWeek: Int {
        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return events.filter { $0.startDate >= now && $0.startDate <= end }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .trailing, spacing: 20) {
                    HStack(spacing: 16) {
                        StatCard(title: "מטלות פתוחות", value: "\(pendingTasks.count)", color: .orange)
                        StatCard(title: "אירועים השבוע", value: "\(eventsThisWeek)", color: .blue)
                    }

                    if let event = nextEvent {
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("השיעור הבא")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(event.title)
                                        .font(.title3.bold())
                                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if !event.location.isEmpty {
                                        Label(event.location, systemImage: "mappin")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        Text("מטלות קרובות")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        if upcomingTasks.isEmpty {
                            HStack {
                                Spacer()
                                Text("אין מטלות קרובות")
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                        } else {
                            ForEach(upcomingTasks) { task in
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(task.title)
                                            .font(.body.bold())
                                        HStack(spacing: 8) {
                                            if let course = task.course {
                                                Text(course.name)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption)
                                                .foregroundStyle(task.dueDate < Date() ? .red : .secondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .background(priorityColor(task.priority).opacity(0.1))
                                    .cornerRadius(10)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(priorityColor(task.priority))
                                        .frame(width: 5)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("שחר לימודים")
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.largeTitle.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
