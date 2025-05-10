//  LockAndWorkWidgetLiveActivity.swift
import ActivityKit
import WidgetKit
import SwiftUI

struct LockAndWorkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LockAndWorkWidgetAttributes.self) { context in
            // Lock screen & banner
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(
                    context.attributes.blockType == .focus
                        ? Color.blue.opacity(0.2)
                        : Color.green.opacity(0.2)
                )
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Leading: icon + label
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Circle()
                            .fill(
                                context.attributes.blockType == .focus
                                    ? Color.blue
                                    : Color.green
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(
                                    systemName: context.attributes.blockType == .focus
                                        ? "brain"
                                        : "cup.and.saucer"
                                )
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            )

                        Text(context.attributes.blockType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }

                // Trailing: timer
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endDate, style: .timer)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .padding(.trailing, 8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                // Bottom: progress + next
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        if context.isStale {
                            Text("Timer may have ended")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ProgressView(
                                value: calculateProgress(context: context),
                                total: 1.0
                            )
                            .progressViewStyle(.linear)
                            .tint(
                                context.attributes.blockType == .focus
                                    ? Color.blue
                                    : Color.green
                            )
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)

                            HStack {
                                Text("Up next: \(context.attributes.blockType.next.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(
                                    context.attributes.blockType == .focus
                                        ? "5 min"
                                        : "25 min"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)  // Reduced padding
                    .padding(.horizontal, 4)  // Added horizontal padding
                }
            }
            compactLeading: {
                Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                    .foregroundColor(context.attributes.blockType == .focus ? .blue : .green)
            }
            compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .frame(width: 50, alignment: .trailing)
                    .lineLimit(1)
            }
            minimal: {
                ZStack {
                    Circle()
                        .fill(context.attributes.blockType == .focus ? Color.blue : Color.green)
                        .frame(width: 24, height: 24)
                    Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            // Add content margins to fix the issue with elements being cut off by Dynamic Island
            .contentMargins(.all, 8, for: .expanded)
            .keylineTint(context.attributes.blockType == .focus ? Color.blue : Color.green)
        }
    }

    /// Calculate the progress of the current timer session (0.0 to 1.0)
    private func calculateProgress(
        context: ActivityViewContext<LockAndWorkWidgetAttributes>
    ) -> Double {
        let endDate = context.state.endDate
        let now = Date()
        let total: TimeInterval = context.attributes.blockType == .focus ? 25*60 : 5*60
        guard endDate > now else { return 1.0 }
        let elapsed = total - endDate.timeIntervalSince(now)
        return min(1, max(0, elapsed / total))
    }
}

/// Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LockAndWorkWidgetAttributes>
    @Environment(\.isActivityFullscreen) private var isFullscreen

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(context.attributes.blockType == .focus ? Color.blue : Color.green)
                        .frame(width: 24, height: 24)
                    Image(systemName: context.attributes.blockType == .focus ? "brain" : "cup.and.saucer")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                Spacer()
                Text(context.state.endDate, style: .timer)
                    .font(.system(size: isFullscreen ? 32 : 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }

            if !context.isStale {
                ProgressView(value: calculateProgress(context: context), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(context.attributes.blockType == .focus ? Color.blue : Color.green)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)

                if isFullscreen {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Up next: \(context.attributes.blockType.next.displayName)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "timer").foregroundColor(.secondary)
                            Text(
                                context.attributes.blockType == .focus
                                    ? "5 min break"
                                    : "25 min focus"
                            )
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Timer may have ended")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func calculateProgress(
        context: ActivityViewContext<LockAndWorkWidgetAttributes>
    ) -> Double {
        let endDate = context.state.endDate
        let now = Date()
        let total: TimeInterval = context.attributes.blockType == .focus ? 25*60 : 5*60
        guard endDate > now else { return 1.0 }
        let elapsed = total - endDate.timeIntervalSince(now)
        return min(1, max(0, elapsed / total))
    }
}
