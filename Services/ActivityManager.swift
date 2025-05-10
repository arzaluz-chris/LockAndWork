//  ActivityManager.swift
import Foundation
import ActivityKit

class ActivityManager {
    static let shared = ActivityManager()
    
    // Reference to current Live Activity
    private var activity: Activity<LockAndWorkWidgetAttributes>?
    
    private init() {}
    
    /// Start a Live Activity
    /// - Parameters:
    ///   - endDate: When the current timer will end
    ///   - blockType: The current block type (focus or break)
    func startActivity(endDate: Date, blockType: BlockType) {
        // End any existing activity first
        endActivity()
        
        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not available")
            return
        }
        
        // Create attributes and initial state
        let attributes = LockAndWorkWidgetAttributes(blockType: blockType)
        let initialState = LockAndWorkWidgetAttributes.ContentState(
            endDate: endDate,
            blockType: blockType
        )
        
        // Try to create the Live Activity
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            
            print("Live Activity started with end date: \(endDate)")
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// Update an existing Live Activity
    /// - Parameters:
    ///   - endDate: When the current timer will end
    ///   - blockType: The current block type (focus or break)
    func updateActivity(endDate: Date, blockType: BlockType) {
        guard let activity = self.activity else {
            // If no activity exists, start a new one
            startActivity(endDate: endDate, blockType: blockType)
            return
        }
        
        // Create new state
        let updatedState = LockAndWorkWidgetAttributes.ContentState(
            endDate: endDate,
            blockType: blockType
        )
        
        // Update the Live Activity
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
            print("Live Activity updated with end date: \(endDate)")
        }
    }
    
    /// End the current Live Activity
    func endActivity() {
        // End the Live Activity if it exists
        guard let activity = activity else { return }
        
        Task {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("Live Activity ended")
            self.activity = nil
        }
    }
}
