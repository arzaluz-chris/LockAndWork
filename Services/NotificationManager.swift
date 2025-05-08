//  NotificationManager.swift
import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("Error requesting permissions: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for blockType: BlockType, at date: Date) {
        let content = UNMutableNotificationContent()
        
        // Configure content based on block type
        switch blockType {
        case .focus:
            content.title = String(localized: "Time to focus!")
            content.body = String(localized: "Your break is over. Time to get back to work.")
        case .break:
            content.title = String(localized: "Break time!")
            content.body = String(localized: "You've completed your focus session. Take a well-deserved break.")
        }
        
        content.sound = .default
        content.categoryIdentifier = "LOCK_AND_WORK"
        
        // Create trigger based on date
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create notification request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func triggerHapticFeedback(for blockType: BlockType) {
        switch blockType {
        case .focus:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .break:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
}

// Notification delegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow notifications to appear even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
