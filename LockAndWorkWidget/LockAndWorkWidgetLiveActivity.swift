//  LockAndWorkWidgetLiveActivity.swift
//  LockAndWorkWidget
//
//  Created by Christian Arzaluz on 07/05/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Import the shared attributes file
// The target membership for SharedActivityAttributes.swift should include both the main app and widget extension
import LockAndWork

struct LockAndWorkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LockAndWorkWidgetAttributes.self) { context in
            // Lock Screen presentation and banner
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(context.attributes.blockType == .focus ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                .activitySystemActionForegroundColor(Color.white)
                
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Circle()
                            .fill(context.attributes.blockType == .focus ? Color.blue : Color.green)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                        
                        Text(context.attributes.blockType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeRemaining(from: context.state.endDate))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .contentTransition(.numericText(countsDown: true))
                        .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        if context.isStale {
                            Text("Timer may have ended")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            // Progress bar
                            ProgressView(value: progressValue(context: context), total: 1.0)
                                .progressViewStyle(.linear)
                                .tint(context.attributes.blockType == .focus ? Color.blue : Color.green)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            // Up next section
                            HStack {
                                Text("Up next: \(context.attributes.blockType.next.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if context.attributes.blockType == .focus {
                                    Text("5 min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("25 min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

            } compactLeading: {
                // Compact leading presentation (left side)
                ZStack {
                    Circle()
                        .fill(context.attributes.blockType == .focus ? Color.blue : Color.green)
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Compact trailing presentation (right side)
                Text(timeRemaining(from: context.state.endDate))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .contentTransition(.numericText(countsDown: true))
            } minimal: {
                // Minimal presentation (when multiple Live Activities are active)
                ZStack {
                    Circle()
                        .fill(context.attributes.blockType == .focus ? Color.blue : Color.green)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .keylineTint(context.attributes.blockType == .focus ? Color.blue : Color.green)
        }
        .widgetURL(URL(string: "lockandwork://timer"))
    }
    
    // Helper function to calculate time remaining
    private func timeRemaining(from endDate: Date) -> String {
        let remaining = max(0, endDate.timeIntervalSinceNow)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Helper function to calculate progress
    private func progressValue(context: ActivityViewContext<LockAndWorkWidgetAttributes>) -> Double {
        let endDate = context.state.endDate
        let totalDuration: TimeInterval
        
        // Determine block type duration
        if context.attributes.blockType == .focus {
            totalDuration = 25 * 60 // Default 25 minutes for focus
        } else {
            totalDuration = 5 * 60 // Default 5 minutes for break
        }
        
        let elapsed = totalDuration - max(0, endDate.timeIntervalSinceNow)
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
}

// Lock Screen presentation view
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LockAndWorkWidgetAttributes>
    // This environment value may not be available in older iOS versions
    // If it causes issues, you can remove it and use a constant size
    @Environment(\.isActivityFullscreen) private var isActivityFullscreen
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Block type indicator
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(context.attributes.blockType == .focus ? Color.blue : Color.green)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    
                    Text(context.attributes.blockType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Time remaining
                Text(timeRemaining(from: context.state.endDate))
                    .font(.system(size: isActivityFullscreen ? 32 : 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(countsDown: true))
            }
            
            if !context.isStale {
                // Progress bar
                ProgressView(value: progressValue(context: context), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(context.attributes.blockType == .focus ? Color.blue : Color.green)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                if isActivityFullscreen {
                    // Additional information for full screen (StandBy mode)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Up next: \(context.attributes.blockType.next.displayName)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.secondary)
                            
                            if context.attributes.blockType == .focus {
                                Text("5 min break")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("25 min focus")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            } else {
                // Stale content indicator
                Text("Timer may have ended")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // Helper function to calculate time remaining
    private func timeRemaining(from endDate: Date) -> String {
        let remaining = max(0, endDate.timeIntervalSinceNow)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Helper function to calculate progress
    private func progressValue(context: ActivityViewContext<LockAndWorkWidgetAttributes>) -> Double {
        let endDate = context.state.endDate
        let totalDuration: TimeInterval
        
        // Determine block type duration
        if context.attributes.blockType == .focus {
            totalDuration = 25 * 60 // Default 25 minutes for focus
        } else {
            totalDuration = 5 * 60 // Default 5 minutes for break
        }
        
        let elapsed = totalDuration - max(0, endDate.timeIntervalSinceNow)
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
}

// Preview data - Using literal values for preview since we're importing the definitions
#Preview("Focus", as: .content) {
   LockAndWorkWidgetLiveActivity()
} contentState: {
    LockAndWorkWidgetAttributes.ContentState(
        endDate: Date().addingTimeInterval(15 * 60),
        blockType: .focus
    )
} attributes: {
    LockAndWorkWidgetAttributes(blockType: .focus)
}

#Preview("Break", as: .content) {
   LockAndWorkWidgetLiveActivity()
} contentState: {
    LockAndWorkWidgetAttributes.ContentState(
        endDate: Date().addingTimeInterval(5 * 60),
        blockType: .break
    )
} attributes: {
    LockAndWorkWidgetAttributes(blockType: .break)
}
