import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScheduleEvent.startDate) private var events: [ScheduleEvent]
    @State private var showingAddEvent = false
    @State private var weekOffset = 0

    private var weekDates: [Date] {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        comps.weekday = cal.firstWeekday
        let weekStart = cal.date(from: comps) ?? now
        let shifted = cal.date(byAdding: .weekOfYear, value: weekOffset, to: weekStart) ?? weekStart
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: shifted) }
    }

    private var weekTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "he")
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: weekDates.first ?? Date())
    }

    private func events(for date: Date) -> [ScheduleEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button { weekOffset += 1 } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    Spacer()
                    Text(weekTitle)
                        .font(.headline)
                    Spacer()
                    Button { weekOffset -= 1 } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        ForEach(weekDates, id: \.self) { date in
                            DayRowView(date: date, events: events(for: date))
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("לוז")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("היום") { weekOffset = 0 }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddEvent = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
            }
        }
    }
}

struct DayRowView: View {
    let date: Date
    let events: [ScheduleEvent]

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    private var dayName: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "he")
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    private var dayNumber: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(dayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(dayNumber)
                    .font(.title3.bold())
                    .frame(width: 36, height: 36)
                    .foregroundStyle(isToday ? .white : .primary)
                    .background(isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())
            }
            .frame(width: 48)

            VStack(alignment: .trailing, spacing: 6) {
                if events.isEmpty {
                    Text("אין אירועים")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 10)
                } else {
                    ForEach(events) { event in
                        EventChipView(event: event)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.vertical, 8)
        }
        .padding(.vertical, 4)
    }
}

struct EventChipView: View {
    let event: ScheduleEvent

    private var chipColor: Color {
        switch event.eventType {
        case .lesson: return .blue
        case .exam: return .red
        case .submission: return .orange
        }
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(event.eventType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(chipColor)
                        .foregroundStyle(.white)
                        .cornerRadius(4)
                    Text(event.title)
                        .font(.caption.bold())
                }
                Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) — \(event.endDate.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(chipColor.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(chipColor.opacity(0.35), lineWidth: 1))
            .cornerRadius(8)
        }
    }
}
