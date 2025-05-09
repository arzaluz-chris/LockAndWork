//  ActivityManager.swift
import Foundation
import ActivityKit

class ActivityManager {
    static let shared = ActivityManager()
    
    // Referencia a la Live Activity actual
    private var activity: Activity<LockAndWorkWidgetAttributes>?
    private var updateTimer: Timer?
    
    private init() {}
    
    func startActivity(endDate: Date, blockType: BlockType) {
        endActivity() // Terminar cualquier actividad existente
        
        // Verificar si están habilitadas las Live Activities
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not available")
            return
        }
        
        // Crear atributos y estado inicial
        let attributes = LockAndWorkWidgetAttributes(blockType: blockType)
        let initialState = LockAndWorkWidgetAttributes.ContentState(
            endDate: endDate,
            blockType: blockType
        )
        
        // Intentar crear la Live Activity
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            
            print("Live Activity started successfully")
            
            // Iniciar las actualizaciones periódicas
            startPeriodicUpdates(endDate: endDate, blockType: blockType)
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(endDate: Date, blockType: BlockType) {
        // Si no hay actividad, iniciar una nueva
        guard let activity = activity else {
            startActivity(endDate: endDate, blockType: blockType)
            return
        }
        
        // Crear nuevo estado
        let updatedState = LockAndWorkWidgetAttributes.ContentState(
            endDate: endDate,
            blockType: blockType
        )
        
        // Actualizar la Live Activity
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    func endActivity() {
        // Detener las actualizaciones periódicas
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Terminar la actividad en vivo
        guard let activity = activity else { return }
        
        Task {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.activity = nil
        }
    }
    
    // Método privado para iniciar actualizaciones periódicas
    private func startPeriodicUpdates(endDate: Date, blockType: BlockType) {
        // Detener timer existente si hay uno
        updateTimer?.invalidate()
        
        // Crear un nuevo timer para actualizaciones periódicas (cada 2 segundos)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.activity != nil else { return }
            
            // Calcular el endDate actualizado basado en el tiempo actual
            let remainingTime = endDate.timeIntervalSinceNow
            if remainingTime <= 0 {
                // Si el tiempo ha expirado, terminar la actividad
                self.endActivity()
                return
            }
            
            // Actualizar con el tiempo restante calculado desde ahora
            let updatedEndDate = Date().addingTimeInterval(remainingTime)
            self.updateActivity(endDate: updatedEndDate, blockType: blockType)
        }
        
        // Asegurar que el timer funcione incluso durante scrolling
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
}
