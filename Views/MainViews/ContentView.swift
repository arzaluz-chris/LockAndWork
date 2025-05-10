//  ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [Settings]
    
    // Create view models
    @State private var timerViewModel: MainTimerViewModel?
    @State private var historyViewModel: HistoryViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    
    // Create a singleton Settings instance if none exists
    private func ensureSettingsExist() {
        if settingsQuery.isEmpty {
            let defaultSettings = Settings.defaultSettings()
            modelContext.insert(defaultSettings)
            try? modelContext.save()
        }
    }
    
    var settings: Settings {
        settingsQuery.first ?? Settings.defaultSettings()
    }
    
    var body: some View {
        TabView {
            if let timerViewModel = timerViewModel {
                TimerView()
                    .environmentObject(timerViewModel)
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
            }
            
            if let historyViewModel = historyViewModel {
                HistoryView()
                    .environmentObject(historyViewModel)
                    .tabItem {
                        Label("History", systemImage: "chart.bar")
                    }
            }
            
            if let settingsViewModel = settingsViewModel {
                SettingsView()
                    .environmentObject(settingsViewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
        }
        .onAppear {
            // Ensure settings exist
            ensureSettingsExist()
            
            // Initialize view models
            if timerViewModel == nil {
                timerViewModel = MainTimerViewModel(
                    modelContext: modelContext,
                    settings: settings
                )
            }
            
            if historyViewModel == nil {
                historyViewModel = HistoryViewModel(modelContext: modelContext)
            }
            
            if settingsViewModel == nil {
                settingsViewModel = SettingsViewModel(modelContext: modelContext)
            }
            
            // Request notification permissions
            NotificationManager.shared.requestPermission { granted in
                print("Notification permission granted: \(granted)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, Settings.self], inMemory: true)
}
