//  ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [Settings]
    
    var settings: Settings {
        settingsQuery.first ?? Settings.defaultSettings()
    }
    
    var body: some View {
        TabView {
            TimerView()
                .environment(\.modelContext, modelContext)
                .environmentObject(MainTimerViewModel(modelContext: modelContext, settings: settings))
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            HistoryView()
                .environment(\.modelContext, modelContext)
                .environmentObject(HistoryViewModel(modelContext: modelContext))
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
            
            SettingsView()
                .environment(\.modelContext, modelContext)
                .environmentObject(SettingsViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
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
