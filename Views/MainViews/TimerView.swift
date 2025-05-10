//  TimerView.swift
import SwiftUI
import SwiftData

struct TimerView: View {
    @EnvironmentObject var viewModel: MainTimerViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    // Colors
    private let focusColor = Color.blue
    private let breakColor = Color.green
    
    // Timer for smooth UI updates (more frequent than the real timer)
    let refreshTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // State to force UI updates
    @State private var refreshID = UUID()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Type label
            Text(viewModel.timerService.currentBlockType.displayName.uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                .padding(.vertical, 8)
                .id("\(viewModel.timerService.currentBlockType)-\(refreshID)")
                .animation(.easeInOut, value: viewModel.timerService.currentBlockType)
            
            // Timer Circle with text
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 15)
                    .frame(width: 280, height: 280)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: viewModel.timerService.timeProgress())
                    .stroke(
                        viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.timerService.timeProgress())
                    .id("progress-\(refreshID)")
                
                // Indicator dot on the progress circle
                if viewModel.timerService.isRunning {
                    let progress = viewModel.timerService.timeProgress()
                    Circle()
                        .fill(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                        .frame(width: 12, height: 12)
                        .offset(
                            x: 140 * cos(2 * .pi * progress - .pi/2),
                            y: 140 * sin(2 * .pi * progress - .pi/2)
                        )
                        .opacity(progress > 0 ? 0.8 : 0)
                        .animation(.linear(duration: 0.1), value: progress)
                        .id("dot-\(refreshID)")
                }
                
                // Time display
                VStack(spacing: 8) {
                    Text(viewModel.timerService.formattedTime())
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .contentTransition(.numericText(countsDown: true))
                        .id("time-\(refreshID)")
                }
            }
            .padding(.bottom, 20)
            
            // Control buttons
            HStack(spacing: 40) {
                if viewModel.isPaused {
                    // Play button
                    Button(action: {
                        viewModel.startTimer()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                            )
                    }
                    .accessibilityLabel("Start timer")
                    
                    // Reset button
                    Button(action: {
                        viewModel.resetTimer()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                            .overlay(
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            )
                    }
                    .accessibilityLabel("Reset timer")
                } else {
                    // Pause button
                    Button(action: {
                        viewModel.pauseTimer()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 5)
                            .overlay(
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                            )
                    }
                    .accessibilityLabel("Pause timer")
                }
            }
            .padding(.bottom, 20)
            
            // Next block info
            NextBlockInfoView(
                blockType: viewModel.getNextBlockInfo().type,
                duration: viewModel.getNextBlockInfo().duration
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        // Force UI updates with the timer
        .onReceive(refreshTimer) { _ in
            if viewModel.timerService.isRunning {
                self.refreshID = UUID() // Force redraw of key elements
            }
        }
        // Handle app lifecycle changes
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // Handle app lifecycle changes to maintain Live Activity
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        // When app goes to background
        if oldPhase == .active && (newPhase == .background || newPhase == .inactive) {
            if viewModel.timerService.isRunning && viewModel.settings.liveActivityEnabled {
                // Start or update Live Activity when app goes to background
                let timeRemaining = TimeInterval(viewModel.timerService.remainingSeconds)
                let endDate = Date().addingTimeInterval(timeRemaining)
                ActivityManager.shared.startActivity(
                    endDate: endDate,
                    blockType: viewModel.timerService.currentBlockType
                )
            }
        } else if oldPhase != .active && newPhase == .active {
            // App becomes active - refresh UI
            refreshID = UUID()
            // Refresh the history view
            if viewModel.settings.liveActivityEnabled {
                ActivityManager.shared.endActivity()
            }
        }
    }
}
