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
    private var endDate: Date?
    private var settings: Settings
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?
    
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
        endDate = nil
        pausedTimeRemaining = nil
        isRunning = false
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        // Calcular la fecha de finalización basada en los segundos restantes
        let totalSeconds = minutesForCurrentBlock() * 60
        
        // Si tenemos tiempo pausado, usamos ese valor para calcular endDate
        if let pausedTime = pausedTimeRemaining {
            remainingSeconds = pausedTime
            endDate = Date().addingTimeInterval(TimeInterval(pausedTime))
            startTime = Date().addingTimeInterval(-TimeInterval(totalSeconds - pausedTime))
        } else {
            remainingSeconds = totalSeconds
            endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
            startTime = Date()
        }
        
        // Limpiar el tiempo pausado
        pausedTimeRemaining = nil
        
        // Crear un nuevo timer que publique cada 0.1 segundos para una UI más fluida
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRemainingTime()
            }
            
        print("Timer started with \(remainingSeconds) seconds remaining")
        print("End date set to: \(endDate?.description ?? "nil")")
        
        // Iniciar Live Activity si está habilitada - solo una vez es suficiente
        // ya que TimelineView mantendrá las actualizaciones
        if settings.liveActivityEnabled, let endDate = endDate {
            ActivityManager.shared.startActivity(
                endDate: endDate,
                blockType: currentBlockType
            )
        }
    }
    
    private func updateRemainingTime() {
        guard isRunning, let end = endDate else { return }
        
        // Calcular segundos restantes basados en la fecha de finalización
        let remaining = max(0, end.timeIntervalSinceNow)
        remainingSeconds = Int(remaining)
        
        // Verificar si el timer llegó a cero
        if remainingSeconds <= 0 {
            completeCurrentBlock()
        }
    }
    
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        stopTimer()
        
        // Guardar el tiempo actual para reanudar desde este punto
        pausedTimeRemaining = remainingSeconds
        startTime = nil
        endDate = nil
        
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
        endDate = nil
        
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
