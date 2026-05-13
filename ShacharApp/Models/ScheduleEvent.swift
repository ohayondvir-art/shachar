import Foundation
import SwiftData

enum EventType: String, Codable, CaseIterable {
    case lesson = "שיעור"
    case exam = "בחינה"
    case submission = "הגשה"
}

@Model
class ScheduleEvent {
    var id: UUID
    var title: String
    var eventType: EventType
    var startDate: Date
    var endDate: Date
    var location: String
    var course: Course?

    init(title: String, eventType: EventType = .lesson, startDate: Date = Date(),
         endDate: Date = Date(), location: String = "", course: Course? = nil) {
        self.id = UUID()
        self.title = title
        self.eventType = eventType
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.course = course
    }
}
