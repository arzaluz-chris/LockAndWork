//  LockAndWorkWidgetLiveActivity.swift
import ActivityKit
import WidgetKit
import SwiftUI

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
                    Text(getTimeRemaining(from: context.state.endDate))
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
                            ProgressView(value: calculateProgress(context: context), total: 1.0)
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
                Text(getTimeRemaining(from: context.state.endDate))
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
    }
    
    // Helper function to calculate time remaining
    private func getTimeRemaining(from endDate: Date) -> String {
        let now = Date()
        let remaining = max(0, endDate.timeIntervalSince(now))
        
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Helper function to calculate progress
    private func calculateProgress(context: ActivityViewContext<LockAndWorkWidgetAttributes>) -> Double {
        let endDate = context.state.endDate
        let now = Date()
        
        // Calcular duración total basada en blockType
        let totalDuration: TimeInterval
        if context.attributes.blockType == .focus {
            totalDuration = 25 * 60 // Por defecto 25 min para focus
        } else {
            totalDuration = 5 * 60 // Por defecto 5 min para break
        }
        
        // Calcular el tiempo transcurrido y restante
        let remainingTime = max(0, endDate.timeIntervalSince(now))
        let elapsedTime = totalDuration - remainingTime
        
        // Asegurar que el progreso esté entre 0 y 1
        return min(1.0, max(0.0, elapsedTime / totalDuration))
    }
}

// Lock Screen presentation view
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LockAndWorkWidgetAttributes>
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
                Text(getTimeRemaining(from: context.state.endDate))
                    .font(.system(size: isActivityFullscreen ? 32 : 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(countsDown: true))
            }
            
            if !context.isStale {
                // Progress bar
                ProgressView(value: calculateProgress(context: context), total: 1.0)
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
    private func getTimeRemaining(from endDate: Date) -> String {
        let now = Date()
        let remaining = max(0, endDate.timeIntervalSince(now))
        
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Helper function to calculate progress
    private func calculateProgress(context: ActivityViewContext<LockAndWorkWidgetAttributes>) -> Double {
        let endDate = context.state.endDate
        let now = Date()
        
        // Calcular duración total basada en blockType
        let totalDuration: TimeInterval
        if context.attributes.blockType == .focus {
            totalDuration = 25 * 60 // Por defecto 25 min para focus
        } else {
            totalDuration = 5 * 60 // Por defecto 5 min para break
        }
        
        // Calcular el tiempo transcurrido y restante
        let remainingTime = max(0, endDate.timeIntervalSince(now))
        let elapsedTime = totalDuration - remainingTime
        
        // Asegurar que el progreso esté entre 0 y 1
        return min(1.0, max(0.0, elapsedTime / totalDuration))
    }
}

#Preview {
    EmptyView()
}
