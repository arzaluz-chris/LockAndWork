//  TimerView.swift
import SwiftUI
import SwiftData

struct TimerView: View {
    @EnvironmentObject var viewModel: MainTimerViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    // State para UI updates
    @State private var timerTick = 0
    
    // Timer para actualizaciones fluidas de UI (más frecuente que el timer real)
    let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    // Colors
    private let focusColor = Color.blue
    private let breakColor = Color.green
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Type label
            Text(viewModel.timerService.currentBlockType.displayName.uppercased())
                .font(.headline)
                .foregroundColor(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                .padding(.vertical, 8)
                .animation(.easeInOut, value: viewModel.timerService.currentBlockType)
            
            // Timer Circle with text
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 15)
                    .frame(width: 280, height: 280)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress())
                    .stroke(
                        viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: progress())
                
                // Indicator dot on the progress circle
                if viewModel.timerService.isRunning {
                    Circle()
                        .fill(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                        .frame(width: 12, height: 12)
                        .offset(
                            x: 140 * cos(2 * .pi * progress() - .pi/2),
                            y: 140 * sin(2 * .pi * progress() - .pi/2)
                        )
                        .opacity(0.8)
                        .animation(.linear(duration: 0.25), value: progress())
                }
                
                // Time display
                VStack(spacing: 8) {
                    Text(viewModel.timerService.formattedTime())
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true)) // iOS 17+ animated countdown
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
        // Force UI updates
        .onReceive(timer) { _ in
            timerTick += 1 // Esto fuerza la actualización de la UI cada 0.25 segundos
        }
        // Handle app lifecycle changes
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // Progress calculation for the circle
    private func progress() -> Double {
        return viewModel.timerService.timeProgress()
    }
    
    // Handle app lifecycle changes to maintain Live Activity
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        // When app goes to background
        if oldPhase == .active && (newPhase == .background || newPhase == .inactive) {
            if !viewModel.isPaused && viewModel.settings.liveActivityEnabled {
                // Start or update Live Activity when app goes to background
                let endDate = Date().addingTimeInterval(TimeInterval(viewModel.timerService.remainingSeconds))
                ActivityManager.shared.startActivity(
                    endDate: endDate,
                    blockType: viewModel.timerService.currentBlockType
                )
            }
        }
        
        // When app comes to foreground
        if newPhase == .active && oldPhase != .active {
            if !viewModel.isPaused && viewModel.settings.liveActivityEnabled {
                // End Live Activity when returning to app while timer is running
                ActivityManager.shared.endActivity()
            }
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(MainTimerViewModel(
            modelContext: try! ModelContainer(for: Session.self, Settings.self).mainContext,
            settings: Settings()
        ))
}
