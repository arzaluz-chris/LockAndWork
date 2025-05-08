//  SettingsViewModel.swift
import Foundation
import SwiftData
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var focusMinutes: Int
    @Published var breakMinutes: Int
    @Published var soundEnabled: Bool
    @Published var hapticsEnabled: Bool
    @Published var liveActivityEnabled: Bool
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Try to fetch existing settings or create default
        let descriptor = FetchDescriptor<Settings>(
            predicate: #Predicate { $0.id == 0 }
        )
        
        var fetchedSettings: Settings?
        do {
            fetchedSettings = try modelContext.fetch(descriptor).first
        } catch {
            print("Failed to fetch settings: \(error)")
        }
        
        let settings = fetchedSettings ?? Settings.defaultSettings()
        if fetchedSettings == nil {
            modelContext.insert(settings)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save default settings: \(error)")
            }
        }
        
        self.settings = settings
        self.focusMinutes = settings.focusMinutes
        self.breakMinutes = settings.breakMinutes
        self.soundEnabled = settings.soundEnabled
        self.hapticsEnabled = settings.hapticsEnabled
        self.liveActivityEnabled = settings.liveActivityEnabled
    }
    
    func saveSettings() {
        settings.focusMinutes = focusMinutes
        settings.breakMinutes = breakMinutes
        settings.soundEnabled = soundEnabled
        settings.hapticsEnabled = hapticsEnabled
        settings.liveActivityEnabled = liveActivityEnabled
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}
