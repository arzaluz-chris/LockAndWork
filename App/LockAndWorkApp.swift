// LockAndWorkApp.swift
import SwiftUI
import SwiftData

@main
struct LockAndWorkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Session.self, Settings.self])
    }
}
