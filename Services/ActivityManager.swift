//  ActivityManager.swift
import Foundation
import ActivityKit

class ActivityManager {
    static let shared = ActivityManager()
    
    private var activity: Activity<FocusAttributes>?
    
    private init() {}
    
    func startActivity(endDate: Date, blockType: BlockType) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not available")
            return
        }
        
        // End any existing activity
        endActivity()
        
        let attributes = FocusAttributes(blockType: blockType)
        let state = FocusAttributes.ContentState(endDate: endDate, blockType: blockType)
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
            print("Live Activity started with ID: \(activity?.id ?? "unknown")")
        } catch {
            print("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(endDate: Date, blockType: BlockType) {
        Task {
            let state = FocusAttributes.ContentState(endDate: endDate, blockType: blockType)
            await activity?.update(using: state)
        }
    }
    
    func endActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
