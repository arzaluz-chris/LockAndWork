//  ActivityManager.swift
import Foundation
import ActivityKit

class ActivityManager {
    static let shared = ActivityManager()
    
    // Referencia a la Live Activity actual
    private var activity: Activity<LockAndWorkWidgetAttributes>?
    
    private init() {}
    
    func startActivity(endDate: Date, blockType: BlockType) {
        // Terminar cualquier actividad existente primero
        endActivity()
        
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
        
        // No establecer staleDate - terminará manualmente cuando sea necesario
        
        // Intentar crear la Live Activity
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            
            print("Live Activity started with end date: \(endDate)")
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(endDate: Date, blockType: BlockType) {
        guard let activity = self.activity else {
            // Si no hay actividad, iniciar una nueva
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
            print("Live Activity updated with end date: \(endDate)")
        }
    }
    
    func endActivity() {
        // Terminar la actividad en vivo si existe
        guard let activity = activity else { return }
        
        Task {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("Live Activity ended")
            self.activity = nil
        }
    }
}
