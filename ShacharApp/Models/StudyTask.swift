import Foundation
import SwiftData

enum TaskPriority: String, Codable, CaseIterable {
    case low = "נמוך"
    case medium = "בינוני"
    case high = "גבוה"
}

@Model
class StudyTask {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var priority: TaskPriority
    var isCompleted: Bool
    var course: Course?

    init(title: String, notes: String = "", dueDate: Date = Date(),
         priority: TaskPriority = .medium, course: Course? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = false
        self.course = course
    }
}
