//  TimerService.swift
import Foundation
import SwiftUI
import Combine
import AVFoundation

class TimerService: ObservableObject {
    // Estados publicados para vinculación de UI
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var currentBlockType: BlockType = .focus
    
    // Estado interno
    private var startTime: Date?
    private var pausedTimeRemaining: Int?
    private var settings: Settings
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?
    private static var lastLiveActivityUpdate = Date()
    
    init(settings: Settings) {
        self.settings = settings
        resetTimer()
        prepareAudioPlayer()
    }
    
    private func prepareAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "bell", withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Could not initialize audio player: \(error)")
        }
    }
    
    func resetTimer() {
        stopTimer()
        remainingSeconds = minutesForCurrentBlock() * 60
        startTime = nil
        pausedTimeRemaining = nil
        isRunning = false
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        // Si tenemos tiempo pausado, calculamos el startTime basado en ese tiempo
        if let pausedTime = pausedTimeRemaining {
            let totalSeconds = Double(minutesForCurrentBlock() * 60)
            let elapsedSeconds = totalSeconds - Double(pausedTime)
            startTime = Date().addingTimeInterval(-elapsedSeconds)
        } else {
            startTime = Date()
            remainingSeconds = minutesForCurrentBlock() * 60
        }
        
        // Limpiar el tiempo pausado
        pausedTimeRemaining = nil
        
        // Crear un nuevo timer que publique cada 0.1 segundos para una UI más fluida
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRemainingTime()
            }
    }
    
    private func updateRemainingTime() {
        guard let start = startTime, isRunning else { return }
        
        let elapsed = Date().timeIntervalSince(start)
        let totalSeconds = Double(minutesForCurrentBlock() * 60)
        
        // Actualizar segundos restantes
        remainingSeconds = max(0, Int(totalSeconds - elapsed))
        
        // Actualizar Live Activity cada 2 segundos (para evitar actualizaciones excesivas)
        let now = Date()
        if now.timeIntervalSince(TimerService.lastLiveActivityUpdate) >= 2 && settings.liveActivityEnabled {
            updateLiveActivity()
            TimerService.lastLiveActivityUpdate = now
        }
        
        // Verificar si el timer llegó a cero
        if remainingSeconds <= 0 {
            completeCurrentBlock()
        }
    }
    
    private func updateLiveActivity() {
        // Calcular la fecha de finalización basada en los segundos restantes
        let updatedEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        
        // Actualizar Live Activity
        ActivityManager.shared.updateActivity(
            endDate: updatedEndDate,
            blockType: currentBlockType
        )
    }
    
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        stopTimer()
        
        // Guardar el tiempo actual para reanudar desde este punto
        pausedTimeRemaining = remainingSeconds
        startTime = nil
        
        // Detener Live Activity
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
    }
    
    func stop() {
        stopTimer()
        resetTimer()
        
        // Detener Live Activity
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    func completeCurrentBlock() {
        // Detener el timer
        stopTimer()
        isRunning = false
        
        // Reproducir sonido si está habilitado
        if settings.soundEnabled {
            audioPlayer?.play()
        }
        
        // Cambiar al siguiente tipo de bloque
        currentBlockType = currentBlockType.next
        
        // Reiniciar el timer con la nueva duración del bloque
        remainingSeconds = minutesForCurrentBlock() * 60
        pausedTimeRemaining = nil
        startTime = nil
        
        // Detener Live Activity
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
    }
    
    func minutesForCurrentBlock() -> Int {
        switch currentBlockType {
        case .focus:
            return settings.focusMinutes
        case .break:
            return settings.breakMinutes
        }
    }
    
    func formattedTime() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func updateSettings(_ newSettings: Settings) {
        self.settings = newSettings
        if !isRunning {
            resetTimer()
        }
    }
    
    func timeProgress() -> Double {
        let totalSeconds = Double(minutesForCurrentBlock() * 60)
        let remaining = Double(remainingSeconds)
        
        // Para evitar división por cero
        if totalSeconds <= 0 {
            return 0
        }
        
        // El progreso es el porcentaje de tiempo que ha pasado
        return (totalSeconds - remaining) / totalSeconds
    }
}
