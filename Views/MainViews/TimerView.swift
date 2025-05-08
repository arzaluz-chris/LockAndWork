//  TimerView.swift
import SwiftUI
import SwiftData

struct TimerView: View {
    @EnvironmentObject var viewModel: MainTimerViewModel
    
    // Estado local para forzar actualizaciones de la UI
    @State private var timerTick = 0
    
    // Timer para forzar actualizaciones de la UI
    let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    // Colores
    private let focusColor = Color.blue
    private let breakColor = Color.green
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Timer Circle con texto
            ZStack {
                // Círculo de fondo
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 15)
                    .frame(width: 280, height: 280)
                
                // Círculo de progreso
                Circle()
                    .trim(from: 0, to: progress())
                    .stroke(
                        viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                
                // Indicador de progreso (punto en el círculo)
                if viewModel.timerService.isRunning {
                    Circle()
                        .fill(viewModel.timerService.currentBlockType == .focus ? focusColor : breakColor)
                        .frame(width: 12, height: 12)
                        .offset(
                            x: 140 * cos(2 * .pi * progress() - .pi/2),
                            y: 140 * sin(2 * .pi * progress() - .pi/2)
                        )
                }
                
                // Texto del temporizador
                VStack(spacing: 8) {
                    Text(viewModel.timerService.formattedTime())
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text(viewModel.timerService.currentBlockType.displayName.uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
            
            // Botones de control
            HStack(spacing: 40) {
                if viewModel.isPaused {
                    // Botón Play
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
                    
                    // Botón Reset
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
                } else {
                    // Botón Pause
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
                }
            }
            .padding(.bottom, 20)
            
            // Información del siguiente bloque
            NextBlockInfoView(
                blockType: viewModel.getNextBlockInfo().type,
                duration: viewModel.getNextBlockInfo().duration
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        // FORZAR ACTUALIZACIÓN DE LA UI CON CADA TICK DEL TIMER
        .onReceive(timer) { _ in
            timerTick += 1
        }
    }
    
    // Cálculo del progreso para el círculo
    private func progress() -> Double {
        let totalSeconds = Double(viewModel.timerService.minutesForCurrentBlock() * 60)
        let remaining = Double(viewModel.timerService.remainingSeconds)
        
        // Asegurar que el progreso esté entre 0 y 1
        return min(1.0, max(0.0, 1.0 - (remaining / totalSeconds)))
    }
}

#Preview {
    TimerView()
        .environmentObject(MainTimerViewModel(
            modelContext: try! ModelContainer(for: Session.self, Settings.self).mainContext,
            settings: Settings()
        ))
}
