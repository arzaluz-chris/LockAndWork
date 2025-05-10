//  TimerService.swift
import Foundation
import SwiftUI
import Combine
import AVFoundation

class TimerService: ObservableObject {
    // Published properties for UI binding
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var currentBlockType: BlockType = .focus
    
    // Internal state
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
    
    /// Prepare the audio player with the bell sound
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
    
    /// Reset the timer to its initial state
    func resetTimer() {
        stopTimer()
        remainingSeconds = minutesForCurrentBlock() * 60
        startTime = nil
        endDate = nil
        pausedTimeRemaining = nil
        isRunning = false
    }
    
    /// Start the timer
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        // Calculate end date based on remaining seconds
        let totalSeconds = minutesForCurrentBlock() * 60
        
        // If we have paused time, use that value to calculate endDate
        if let pausedTime = pausedTimeRemaining {
            remainingSeconds = pausedTime
            endDate = Date().addingTimeInterval(TimeInterval(pausedTime))
            startTime = Date().addingTimeInterval(-TimeInterval(totalSeconds - pausedTime))
        } else {
            remainingSeconds = totalSeconds
            endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
            startTime = Date()
        }
        
        // Clear paused time
        pausedTimeRemaining = nil
        
        // Create a new timer that publishes every 0.1 seconds for a smoother UI
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRemainingTime()
            }
            
        print("Timer started with \(remainingSeconds) seconds remaining")
        print("End date set to: \(endDate?.description ?? "nil")")
    }
    
    /// Update the remaining time based on the end date
    private func updateRemainingTime() {
        guard isRunning, let end = endDate else { return }
        
        // Calculate remaining seconds based on end date
        let remaining = max(0, end.timeIntervalSinceNow)
        remainingSeconds = Int(remaining)
        
        // Check if timer reached zero
        if remainingSeconds <= 0 {
            completeCurrentBlock()
        }
    }
    
    /// Pause the timer
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        stopTimer()
        
        // Save current time for resuming from this point
        pausedTimeRemaining = remainingSeconds
        startTime = nil
        endDate = nil
    }
    
    /// Stop the timer completely
    func stop() {
        stopTimer()
        resetTimer()
    }
    
    /// Stop the timer without resetting
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    /// Complete the current block and prepare for next block
    func completeCurrentBlock() {
        // Stop timer
        stopTimer()
        isRunning = false
        
        // Play sound if enabled
        if settings.soundEnabled {
            audioPlayer?.play()
        }
        
        // Reset timer with current block type
        // Note: We don't change the block type here - that's handled in MainTimerViewModel
        remainingSeconds = 0
        pausedTimeRemaining = nil
        startTime = nil
        endDate = nil
    }
    
    /// Get the minutes for the current block type from settings
    func minutesForCurrentBlock() -> Int {
        switch currentBlockType {
        case .focus:
            return settings.focusMinutes
        case .break:
            return settings.breakMinutes
        }
    }
    
    /// Format the remaining time as a string (MM:SS)
    func formattedTime() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Update the settings and reset timer if not running
    func updateSettings(_ newSettings: Settings) {
        self.settings = newSettings
        if !isRunning {
            resetTimer()
        }
    }
    
    /// Calculate the progress of the timer (0.0 to 1.0)
    func timeProgress() -> Double {
        let totalSeconds = Double(minutesForCurrentBlock() * 60)
        let remaining = Double(remainingSeconds)
        
        // Avoid division by zero
        if totalSeconds <= 0 {
            return 0
        }
        
        // Progress is the percentage of time that has passed
        return min(1.0, max(0.0, (totalSeconds - remaining) / totalSeconds))
    }
}
