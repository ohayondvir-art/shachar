import SwiftUI
import SwiftData

struct CoursesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var showingAddCourse = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(courses) { course in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: course.colorHex) ?? .blue)
                            .frame(width: 14, height: 14)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(course.name)
                                .font(.body)
                            if !course.lecturer.isEmpty {
                                Text(course.lecturer)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(course.credits) נק\"ז")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { modelContext.delete(courses[i]) }
                }
            }
            .navigationTitle("קורסים")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddCourse = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView()
            }
            .overlay {
                if courses.isEmpty {
                    ContentUnavailableView(
                        "אין קורסים",
                        systemImage: "book.fill",
                        description: Text("לחץ על + כדי להוסיף קורס")
                    )
                }
            }
        }
    }
}
