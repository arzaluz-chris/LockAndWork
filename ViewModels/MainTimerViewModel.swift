//  MainTimerViewModel.swift
import Foundation
import SwiftData
import Combine

@MainActor
class MainTimerViewModel: ObservableObject {
    @Published var timerService: TimerService
    @Published var isPaused: Bool = true
    @Published var currentSession: Session?
    
    private var modelContext: ModelContext
    private var settings: Settings
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, settings: Settings) {
        self.modelContext = modelContext
        self.settings = settings
        self.timerService = TimerService(settings: settings)
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        timerService.$isRunning
            .sink { [weak self] isRunning in
                self?.isPaused = !isRunning
                
                if isRunning {
                    self?.startSessionIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    func startTimer() {
        timerService.start()
        
        if timerService.currentBlockType == .focus && settings.liveActivityEnabled {
            if let endDate = Date().addingTimeInterval(TimeInterval(timerService.remainingSeconds)) {
                ActivityManager.shared.startActivity(
                    endDate: endDate,
                    blockType: timerService.currentBlockType
                )
            }
        }
    }
    
    func pauseTimer() {
        timerService.pause()
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
    }
    
    func resetTimer() {
        timerService.stop()
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
        currentSession = nil
    }
    
    func handleBlockCompletion() {
        // Save completed session
        saveCurrentSession()
        
        // Trigger notification
        if settings.soundEnabled {
            let nextBlockType = timerService.currentBlockType.next
            NotificationManager.shared.scheduleNotification(
                for: nextBlockType,
                at: Date()
            )
        }
        
        // Trigger haptic feedback
        if settings.hapticsEnabled {
            NotificationManager.shared.triggerHapticFeedback(
                for: timerService.currentBlockType
            )
        }
        
        // Start new session for next block
        startSessionIfNeeded()
        
        // Update or end Live Activity
        if settings.liveActivityEnabled {
            if timerService.currentBlockType == .focus {
                if let endDate = Date().addingTimeInterval(TimeInterval(timerService.remainingSeconds)) {
                    ActivityManager.shared.updateActivity(
                        endDate: endDate,
                        blockType: timerService.currentBlockType
                    )
                }
            } else {
                ActivityManager.shared.endActivity()
            }
        }
    }
    
    private func startSessionIfNeeded() {
        guard currentSession == nil else { return }
        
        let newSession = Session(
            startDate: Date(),
            type: timerService.currentBlockType
        )
        
        currentSession = newSession
    }
    
    private func saveCurrentSession() {
        guard let session = currentSession else { return }
        
        session.endDate = Date()
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            currentSession = nil
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func getNextBlockInfo() -> (type: BlockType, duration: Int) {
        let nextType = timerService.currentBlockType.next
        let duration = nextType == .focus ? settings.focusMinutes : settings.breakMinutes
        return (nextType, duration)
    }
}
