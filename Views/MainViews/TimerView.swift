//  TimerView.swift
import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: MainTimerViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Timer Circle
            ZStack {
                CircularProgressView(
                    progress: progress(),
                    strokeWidth: 10
                )
                .frame(width: 250, height: 250)
                
                VStack(spacing: 5) {
                    Text(viewModel.timerService.formattedTime())
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    Text(viewModel.timerService.currentBlockType.displayName.uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Control Button
                Button(action: toggleTimer) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .shadow(radius: 5)
                        .overlay(
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.title)
                                .foregroundColor(.primary)
                        )
                }
            }
            
            // Next block info
            NextBlockInfoView(
                blockType: viewModel.getNextBlockInfo().type,
                duration: viewModel.getNextBlockInfo().duration
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Reset button
            Button(action: {
                viewModel.resetTimer()
            }) {
                Text("Reset")
                    .foregroundColor(.red)
                    .padding()
            }
            .opacity(viewModel.isPaused ? 1.0 : 0.0)
            .animation(.easeInOut, value: viewModel.isPaused)
        }
        .padding()
    }
    
    private func toggleTimer() {
        if viewModel.isPaused {
            viewModel.startTimer()
        } else {
            viewModel.pauseTimer()
        }
    }
    
    private func progress() -> Double {
        let totalSeconds = viewModel.timerService.currentBlockType == .focus ?
            viewModel.settings.focusMinutes * 60 :
            viewModel.settings.breakMinutes * 60
        
        let remaining = Double(viewModel.timerService.remainingSeconds)
        
        return 1.0 - (remaining / Double(totalSeconds))
    }
}

#Preview {
    TimerView()
        .environmentObject(MainTimerViewModel(
            modelContext: try! ModelContainer(for: Session.self, Settings.self).mainContext,
            settings: Settings()
        ))
}
