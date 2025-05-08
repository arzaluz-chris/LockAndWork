//  FocusLiveActivityView.swift
import SwiftUI
import WidgetKit
import ActivityKit

struct FocusLiveActivityView: View {
    let state: LockAndWorkWidgetAttributes.ContentState
    let isCompact: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(state.blockType.displayName.uppercased())
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.bold)
                
                if !isCompact {
                    Text("Time remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(timeRemaining())
                .font(isCompact ? .callout : .title3)
                .fontWeight(.bold)
                .monospacedDigit()
            
            if !isCompact {
                Button(action: {}) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "pause.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal, isCompact ? 8 : 16)
        .padding(.vertical, isCompact ? 4 : 12)
        .frame(maxWidth: .infinity)
    }
    
    private func timeRemaining() -> String {
        let remaining = max(0, state.endDate.timeIntervalSinceNow)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusLiveActivityViewCompact: View {
    let state: LockAndWorkWidgetAttributes.ContentState
    
    var body: some View {
        FocusLiveActivityView(state: state, isCompact: true)
    }
}

struct FocusLiveActivityViewExpanded: View {
    let state: LockAndWorkWidgetAttributes.ContentState
    
    var body: some View {
        FocusLiveActivityView(state: state, isCompact: false)
    }
}
