//  ActivityManager.swift
import Foundation
import ActivityKit
import OSLog

class ActivityManager {
    static let shared = ActivityManager()
    
    private var activity: Activity<LockAndWorkWidgetAttributes>?
    private let logger = Logger(subsystem: "com.christian-arzaluz.LockAndWork", category: "ActivityManager")
    
    private init() {}
    
    func startActivity(endDate: Date, blockType: BlockType) {
        // Check if activities are enabled by the system and user
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities not available: disabled by system or user")
            return
        }
        
        // End any existing activity
        endActivity()
        
        // Create activity attributes and state
        let attributes = LockAndWorkWidgetAttributes(blockType: blockType)
        let state = LockAndWorkWidgetAttributes.ContentState(endDate: endDate, blockType: blockType)
        
        do {
            // Request Live Activity
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate.addingTimeInterval(60)),
                pushType: nil // Set to .token if you want push notifications support
            )
            
            logger.info("Live Activity started with ID: \(self.activity?.id ?? "unknown")")
            
            // Set up a task to handle activity updates
            if let activity = activity {
                Task {
                    // Observe content updates
                    for await contentState in activity.contentUpdates {
                        logger.debug("Received content update for Live Activity: \(contentState.blockType.displayName)")
                    }
                    
                    // Observe activity state updates
                    for await activityState in activity.activityStateUpdates {
                        logger.debug("Activity state changed to: \(String(describing: activityState))")
                        
                        // If the activity becomes stale or is dismissed, we should clean up
                        if activityState == .stale || activityState == .dismissed {
                            self.activity = nil
                        }
                    }
                }
            }
        } catch {
            logger.error("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(endDate: Date, blockType: BlockType) {
        guard let activity = activity else {
            logger.warning("Attempted to update Live Activity but none exists")
            return
        }
        
        let state = LockAndWorkWidgetAttributes.ContentState(endDate: endDate, blockType: blockType)
        
        Task {
            await activity.update(ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60)))
            logger.info("Updated Live Activity to: \(blockType.displayName) with end date: \(endDate)")
        }
    }
    
    func endActivity() {
        guard let activity = activity else {
            return
        }
        
        Task {
            // Get current state and update the end content state
            let currentState = activity.content.state
            
            // End the activity with a reasonable dismissal policy
            await activity.end(
                ActivityContent(state: currentState, staleDate: nil),
                dismissalPolicy: .default
            )
            
            logger.info("Ended Live Activity")
            self.activity = nil
        }
    }
    
    var hasActiveActivity: Bool {
        return activity != nil
    }
}
