import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var courses: [Course]

    @State private var title = ""
    @State private var eventType: EventType = .lesson
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var location = ""
    @State private var selectedCourse: Course?

    var body: some View {
        NavigationStack {
            Form {
                Section("פרטי האירוע") {
                    TextField("שם האירוע", text: $title)
                        .multilineTextAlignment(.trailing)
                    TextField("מיקום (אופציונלי)", text: $location)
                        .multilineTextAlignment(.trailing)
                }

                Section("סוג") {
                    Picker("סוג", selection: $eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("זמנים") {
                    DatePicker("התחלה", selection: $startDate)
                        .environment(\.locale, Locale(identifier: "he"))
                        .onChange(of: startDate) { _, newVal in
                            if endDate < newVal {
                                endDate = Calendar.current.date(byAdding: .hour, value: 2, to: newVal) ?? newVal
                            }
                        }
                    DatePicker("סיום", selection: $endDate, in: startDate...)
                        .environment(\.locale, Locale(identifier: "he"))
                }

                if !courses.isEmpty {
                    Section("קורס") {
                        Picker("קורס", selection: $selectedCourse) {
                            Text("ללא קורס").tag(Optional<Course>.none)
                            ForEach(courses) { course in
                                Text(course.name).tag(Optional(course))
                            }
                        }
                    }
                }
            }
            .navigationTitle("אירוע חדש")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func save() {
        let event = ScheduleEvent(
            title: title.trimmingCharacters(in: .whitespaces),
            eventType: eventType,
            startDate: startDate,
            endDate: endDate,
            location: location,
            course: selectedCourse
        )
        modelContext.insert(event)
        dismiss()
    }
}
