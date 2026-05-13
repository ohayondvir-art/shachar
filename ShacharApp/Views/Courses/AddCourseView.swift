import SwiftUI
import SwiftData

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var lecturer = ""
    @State private var credits = 3
    @State private var colorHex = "#007AFF"

    private let palette: [(hex: String, label: String)] = [
        ("#007AFF", "כחול"),   ("#34C759", "ירוק"),
        ("#FF3B30", "אדום"),   ("#FF9500", "כתום"),
        ("#AF52DE", "סגול"),   ("#5AC8FA", "תכלת"),
        ("#FF2D55", "ורוד"),   ("#A2845E", "חום"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("פרטי הקורס") {
                    TextField("שם הקורס", text: $name)
                        .multilineTextAlignment(.trailing)
                    TextField("שם המרצה (אופציונלי)", text: $lecturer)
                        .multilineTextAlignment(.trailing)
                }

                Section("נקודות זכות") {
                    Stepper("\(credits) נק\"ז", value: $credits, in: 1...6)
                }

                Section("צבע") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(palette, id: \.hex) { item in
                            Button {
                                colorHex = item.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: item.hex) ?? .blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white, lineWidth: colorHex == item.hex ? 3 : 0)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: colorHex == item.hex ? 3 : 0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("קורס חדש")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func save() {
        let course = Course(
            name: name.trimmingCharacters(in: .whitespaces),
            lecturer: lecturer,
            credits: credits,
            colorHex: colorHex
        )
        modelContext.insert(course)
        dismiss()
    }
}
