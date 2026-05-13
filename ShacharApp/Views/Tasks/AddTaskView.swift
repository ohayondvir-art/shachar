import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var courses: [Course]

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var priority: TaskPriority = .medium
    @State private var selectedCourse: Course?

    var body: some View {
        NavigationStack {
            Form {
                Section("פרטי המטלה") {
                    TextField("שם המטלה", text: $title)
                        .multilineTextAlignment(.trailing)
                    TextField("הערות", text: $notes, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3...6)
                }

                Section("תאריך הגשה") {
                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "he"))
                }

                Section("עדיפות") {
                    Picker("עדיפות", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
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
            .navigationTitle("מטלה חדשה")
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
        let task = StudyTask(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            course: selectedCourse
        )
        modelContext.insert(task)
        dismiss()
    }
}
