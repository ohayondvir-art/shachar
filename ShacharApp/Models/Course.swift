import Foundation
import SwiftData

@Model
class Course {
    var id: UUID
    var name: String
    var lecturer: String
    var credits: Int
    var colorHex: String

    init(name: String, lecturer: String = "", credits: Int = 3, colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.lecturer = lecturer
        self.credits = credits
        self.colorHex = colorHex
    }
}
