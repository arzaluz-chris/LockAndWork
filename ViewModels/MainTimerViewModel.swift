//  MainTimerViewModel.swift
import Foundation
import SwiftData
import Combine

@MainActor
class MainTimerViewModel: ObservableObject {
    @Published var timerService: TimerService
    @Published var isPaused: Bool = true
    @Published var currentSession: Session?
    
    // Make settings public to allow access from views
    var settings: Settings
    
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, settings: Settings) {
        self.modelContext = modelContext
        self.settings = settings
        self.timerService = TimerService(settings: settings)
        
        setupSubscriptions()
    }
    
    /// Set up Combine subscribers for timer events
    private func setupSubscriptions() {
        // Observe timerService.isRunning to update isPaused
        timerService.$isRunning
            .sink { [weak self] isRunning in
                self?.isPaused = !isRunning
                
                if isRunning {
                    self?.startSessionIfNeeded()
                }
            }
            .store(in: &cancellables)
            
        // Observe when timer reaches zero
        timerService.$remainingSeconds
            .filter { $0 <= 0 }
            .sink { [weak self] _ in
                if self?.timerService.isRunning == false {
                    self?.handleBlockCompletion()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Start the timer and create a Live Activity if enabled
    func startTimer() {
        print("Starting timer...")
        
        // Start the internal timer
        timerService.start()
        
        // Start Live Activity if enabled
        if settings.liveActivityEnabled {
            let endDate = Date().addingTimeInterval(TimeInterval(timerService.remainingSeconds))
            ActivityManager.shared.startActivity(
                endDate: endDate,
                blockType: timerService.currentBlockType
            )
        }
        
        // Start a new session if needed
        startSessionIfNeeded()
    }
    
    /// Pause the timer and end Live Activity
    func pauseTimer() {
        print("Pausing timer...")
        timerService.pause()
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
    }
    
    /// Reset the timer and end Live Activity
    func resetTimer() {
        print("Resetting timer...")
        timerService.stop()
        if settings.liveActivityEnabled {
            ActivityManager.shared.endActivity()
        }
        
        // If there's a current session in progress, save it with the current time as end time
        if let session = currentSession, session.endDate == nil {
            session.endDate = Date()
            try? modelContext.save()
            notifySessionsChanged()
        }
        
        currentSession = nil
    }
    
    /// Handle completion of a timer block
    func handleBlockCompletion() {
        print("Block completed! Saving session...")
        
        // Store the current block type before changing it
        let completedBlockType = timerService.currentBlockType
        
        // Save completed session
        saveCurrentSession()
        
        // Switch to the next block type
        timerService.currentBlockType = completedBlockType.next
        
        // Trigger notification
        if settings.soundEnabled {
            // Schedule notification for the completed block
            NotificationManager.shared.scheduleNotification(
                for: completedBlockType.next,
                at: Date()
            )
        }
        
        // Trigger haptic feedback
        if settings.hapticsEnabled {
            NotificationManager.shared.triggerHapticFeedback(
                for: completedBlockType
            )
        }
        
        // Start new session for next block
        startSessionIfNeeded()
        
        // Update or end Live Activity
        if settings.liveActivityEnabled {
            let endDate = Date().addingTimeInterval(TimeInterval(timerService.remainingSeconds))
            ActivityManager.shared.startActivity(
                endDate: endDate,
                blockType: timerService.currentBlockType
            )
        }
    }
    
    /// Start a new session if one is not already in progress
    private func startSessionIfNeeded() {
        guard currentSession == nil else { return }
        
        let newSession = Session(
            startDate: Date(),
            type: timerService.currentBlockType
        )
        
        // Insert the session into the model context directly
        modelContext.insert(newSession)
        currentSession = newSession
        
        print("Created new session of type: \(timerService.currentBlockType.displayName)")
    }
    
    /// Save the current session to the database
    private func saveCurrentSession() {
        guard let session = currentSession else { return }
        
        // Only set the end date if it's not already set
        if session.endDate == nil {
            session.endDate = Date()
        }
        
        // If the session isn't in the model context yet, insert it
        if session.modelContext == nil {
            modelContext.insert(session)
        }
        
        do {
            try modelContext.save()
            print("Successfully saved session to database")
            // Clear current session after saving
            currentSession = nil
            // Notify that sessions have changed
            notifySessionsChanged()
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    /// Notify that sessions have changed
    private func notifySessionsChanged() {
        // Post a notification that the sessions have changed
        NotificationCenter.default.post(name: NSNotification.Name("SessionsDidChange"), object: nil)
    }
    
    /// Get information about the next block
    /// - Returns: Tuple with the next block type and duration
    func getNextBlockInfo() -> (type: BlockType, duration: Int) {
        let nextType = timerService.currentBlockType.next
        let duration = nextType == .focus ? settings.focusMinutes : settings.breakMinutes
        return (nextType, duration)
    }
}
