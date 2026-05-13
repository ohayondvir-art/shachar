import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyTask.dueDate) private var tasks: [StudyTask]
    @State private var showingAddTask = false
    @State private var showCompleted = false

    private var filtered: [StudyTask] {
        tasks.filter { showCompleted ? $0.isCompleted : !$0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { task in
                    TaskRowView(task: task)
                        .swipeActions(edge: .leading) {
                            Button {
                                task.isCompleted.toggle()
                            } label: {
                                Label(task.isCompleted ? "בטל" : "הושלם",
                                      systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                            }
                            .tint(task.isCompleted ? .orange : .green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(task)
                            } label: {
                                Label("מחק", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("מטלות")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCompleted.toggle()
                    } label: {
                        Label(showCompleted ? "פתוחות" : "הושלמו",
                              systemImage: showCompleted ? "circle" : "checkmark.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTask = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        showCompleted ? "אין מטלות שהושלמו" : "אין מטלות",
                        systemImage: showCompleted ? "checkmark.circle" : "checklist",
                        description: Text(showCompleted ? "" : "החלק שמאלה להוספה, ימינה לסימון הושלם")
                    )
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: StudyTask

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: 8) {
                    Spacer()
                    if let course = task.course {
                        Text(course.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(dueDateColor)
                    Image(systemName: priorityIcon)
                        .font(.caption)
                        .foregroundStyle(priorityColor)
                }
            }

            RoundedRectangle(cornerRadius: 3)
                .fill(priorityColor)
                .frame(width: 4, height: 44)
        }
    }

    private var dueDateColor: Color {
        if task.isCompleted { return .secondary }
        if task.dueDate < Date() { return .red }
        if Calendar.current.isDateInTomorrow(task.dueDate) { return .orange }
        return .secondary
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var priorityIcon: String {
        switch task.priority {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "exclamationmark.circle"
        }
    }
}
