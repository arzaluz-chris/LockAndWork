//  Session.swift
import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var type: BlockType
    
    init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil, type: BlockType) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
    }
    
    var duration: TimeInterval {
        guard let endDate = endDate else { return 0 }
        return endDate.timeIntervalSince(startDate)
    }
    
    var durationInMinutes: Int {
        return Int(duration / 60)
    }
    
    var isCompleted: Bool {
        return endDate != nil
    }
}
