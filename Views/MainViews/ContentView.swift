//  ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [Settings]
    
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
            // Crear explícitamente las instancias de ViewModel y pasarlas como environmentObject
            TimerView()
                .environmentObject(MainTimerViewModel(
                    modelContext: modelContext,
                    settings: settings
                ))
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            HistoryView()
                .environmentObject(HistoryViewModel(modelContext: modelContext))
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
            
            SettingsView()
                .environmentObject(SettingsViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            // Ensure settings exist
            ensureSettingsExist()
            
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
