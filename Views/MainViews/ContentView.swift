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
            SimplePomodoroView()
                .environment(\.modelContext, modelContext)
                .environmentObject(HistoryViewModel(modelContext: modelContext))
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

// Nueva vista simplificada de Pomodoro
struct SimplePomodoroView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @Query private var settingsQuery: [Settings]
    
    var settings: Settings {
        settingsQuery.first ?? Settings.defaultSettings()
    }
    
    @State private var isActive = false
    @State private var timeRemaining: Int = 0
    @State private var mode: BlockType = .focus
    @State private var progress: Double = 0
    @State private var currentSession: Session? = nil
    
    // Para calcular el tiempo de manera precisa
    @State private var startTime: Date? = nil
    @State private var elapsedTime: TimeInterval = 0
    
    // Usar intervalo más corto para UI fluida, pero sin afectar el conteo
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Timer Circle with progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 15)
                    .frame(width: 280, height: 280)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        mode == .focus ? Color.blue : Color.green,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                
                // Progress indicator (small dot on circle)
                if isActive {
                    Circle()
                        .fill(mode == .focus ? Color.blue : Color.green)
                        .frame(width: 12, height: 12)
                        .offset(
                            x: 140 * cos(2 * .pi * progress - .pi/2),
                            y: 140 * sin(2 * .pi * progress - .pi/2)
                        )
                }
                
                // Timer text
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text(mode.displayName.uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
            
            // Control buttons
            HStack(spacing: 40) {
                if isActive {
                    // Pause button
                    Button(action: pauseTimer) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                            .overlay(
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(mode == .focus ? Color.blue : Color.green)
                            )
                    }
                } else {
                    // Start button
                    Button(action: startTimer) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(mode == .focus ? Color.blue : Color.green)
                            )
                    }
                    
                    // Reset button
                    Button(action: resetTimer) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                            .overlay(
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            )
                    }
                }
            }
            .padding(.bottom, 20)
            
            // Next block info
            Text("Siguiente: \(nextMode.displayName) - \(nextModeMinutes) min")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            resetTimer() // Inicializar el timer con los valores correctos
        }
        .onReceive(timer) { currentTime in
            if isActive {
                if let startTime = startTime {
                    // Calcular tiempo transcurrido desde el inicio
                    let elapsed = currentTime.timeIntervalSince(startTime)
                    let totalDuration = Double(getMinutesForCurrentMode() * 60)
                    
                    // Actualizar tiempo restante
                    timeRemaining = max(0, Int(totalDuration - elapsed))
                    
                    // Actualizar progreso para la UI
                    progress = min(1.0, max(0.0, elapsed / totalDuration))
                    
                    // Verificar si el timer terminó
                    if timeRemaining <= 0 {
                        completeCurrentSession()
                    }
                }
            }
        }
    }
    
    // Computed properties
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var nextMode: BlockType {
        return mode == .focus ? .break : .focus
    }
    
    private var nextModeMinutes: Int {
        return nextMode == .focus ? settings.focusMinutes : settings.breakMinutes
    }
    
    // Methods
    private func startTimer() {
        if currentSession == nil {
            currentSession = Session(
                startDate: Date(),
                type: mode
            )
        }
        
        isActive = true
        startTime = Date()
    }
    
    private func pauseTimer() {
        isActive = false
        
        // Guardar el tiempo restante cuando se pausa
        if let startTime = startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let totalDuration = Double(getMinutesForCurrentMode() * 60)
            timeRemaining = max(0, Int(totalDuration - elapsed))
        }
        
        startTime = nil
    }
    
    private func resetTimer() {
        isActive = false
        timeRemaining = getMinutesForCurrentMode() * 60
        progress = 0
        startTime = nil
        currentSession = nil
    }
    
    private func completeCurrentSession() {
        // Save the current session
        if let session = currentSession {
            session.endDate = Date()
            modelContext.insert(session)
            
            do {
                try modelContext.save()
                historyViewModel.loadSessions() // Reload history
            } catch {
                print("Failed to save session: \(error)")
            }
        }
        
        // Play sound and vibration
        NotificationManager.shared.triggerHapticFeedback(for: mode)
        
        // Switch to next mode
        mode = nextMode
        isActive = false
        timeRemaining = getMinutesForCurrentMode() * 60
        progress = 0
        startTime = nil
        
        // Create new session
        currentSession = nil
    }
    
    private func getMinutesForCurrentMode() -> Int {
        return mode == .focus ? settings.focusMinutes : settings.breakMinutes
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, Settings.self], inMemory: true)
}
