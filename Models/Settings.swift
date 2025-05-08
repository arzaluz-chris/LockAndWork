//  Settings.swift
import Foundation
import SwiftData

@Model
final class Settings {
    @Attribute(.unique) var id: Int = 0
    var focusMinutes: Int
    var breakMinutes: Int
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var liveActivityEnabled: Bool
    
    init(id: Int = 0,
         focusMinutes: Int = 25,
         breakMinutes: Int = 5,
         soundEnabled: Bool = true,
         hapticsEnabled: Bool = true,
         liveActivityEnabled: Bool = true) {
        self.id = id
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.liveActivityEnabled = liveActivityEnabled
    }
    
    static func defaultSettings() -> Settings {
        return Settings()
    }
}
