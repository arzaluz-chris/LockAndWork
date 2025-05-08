//  SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Duration") {
                    HStack {
                        Text("Focus time")
                        Spacer()
                        Stepper("\(viewModel.focusMinutes) min", value: $viewModel.focusMinutes, in: 5...60, step: 5)
                    }
                    
                    HStack {
                        Text("Break time")
                        Spacer()
                        Stepper("\(viewModel.breakMinutes) min", value: $viewModel.breakMinutes, in: 1...30, step: 1)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Sound", isOn: $viewModel.soundEnabled)
                    Toggle("Vibration", isOn: $viewModel.hapticsEnabled)
                    Toggle("Live Activity", isOn: $viewModel.liveActivityEnabled)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: viewModel.focusMinutes) { viewModel.saveSettings() }
            .onChange(of: viewModel.breakMinutes) { viewModel.saveSettings() }
            .onChange(of: viewModel.soundEnabled) { viewModel.saveSettings() }
            .onChange(of: viewModel.hapticsEnabled) { viewModel.saveSettings() }
            .onChange(of: viewModel.liveActivityEnabled) { viewModel.saveSettings() }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel(
            modelContext: try! ModelContainer(for: Settings.self).mainContext
        ))
}
