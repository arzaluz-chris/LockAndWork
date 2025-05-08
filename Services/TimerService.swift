//  TimerService.swift
import Foundation
import Combine

class TimerService: ObservableObject {
    // Published states
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var currentBlockType: BlockType = .focus
    
    // Internal state
    private var cancellable: AnyCancellable?
    private var endDate: Date?
    private var settings: Settings
    
    init(settings: Settings) {
        self.settings = settings
        resetTimer()
    }
    
    func resetTimer() {
        self.remainingSeconds = minutesForCurrentBlock() * 60
        self.endDate = nil
        self.isRunning = false
    }
    
    func start() {
        guard !isRunning else { return }
        
        // Calculate end time
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        
        // Start timer that updates every second
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        cancellable?.cancel()
        
        // Save remaining time
        if let endDate = endDate {
            remainingSeconds = max(0, Int(endDate.timeIntervalSinceNow))
        }
        
        self.endDate = nil
    }
    
    func stop() {
        pause()
        resetTimer()
    }
    
    private func tick() {
        guard let end = endDate else { return }
        
        let remaining = max(0, end.timeIntervalSinceNow)
        remainingSeconds = Int(remaining)
        
        // If timer reaches zero, move to next block
        if remainingSeconds == 0 {
            completeCurrentBlock()
        }
    }
    
    func completeCurrentBlock() {
        cancellable?.cancel()
        isRunning = false
        
        // Change to next block type
        currentBlockType = currentBlockType.next
        
        // Reset timer with new block duration
        remainingSeconds = minutesForCurrentBlock() * 60
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
}
