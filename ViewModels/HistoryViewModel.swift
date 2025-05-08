//  HistoryViewModel.swift
import Foundation
import SwiftData
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var sessionsByDate: [Date: [Session]] = [:]
    @Published var totalFocusTimeByDate: [Date: TimeInterval] = [:]
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }
    
    func loadSessions() {
        do {
            let descriptor = FetchDescriptor<Session>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            let sessions = try modelContext.fetch(descriptor)
            processSessions(sessions)
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }
    
    private func processSessions(_ sessions: [Session]) {
        var newSessionsByDate: [Date: [Session]] = [:]
        var newTotalFocusTimeByDate: [Date: TimeInterval] = [:]
        
        for session in sessions {
            guard let endDate = session.endDate else { continue }
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: session.startDate)
            guard let date = calendar.date(from: dateComponents) else { continue }
            
            // Group sessions by date
            if newSessionsByDate[date] == nil {
                newSessionsByDate[date] = [session]
            } else {
                newSessionsByDate[date]?.append(session)
            }
            
            // Calculate total focus time by date
            if session.type == .focus {
                let duration = endDate.timeIntervalSince(session.startDate)
                if newTotalFocusTimeByDate[date] == nil {
                    newTotalFocusTimeByDate[date] = duration
                } else {
                    newTotalFocusTimeByDate[date]! += duration
                }
            }
        }
        
        // Sort sessions within each date
        for (date, sessions) in newSessionsByDate {
            newSessionsByDate[date] = sessions.sorted { $0.startDate > $1.startDate }
        }
        
        sessionsByDate = newSessionsByDate
        totalFocusTimeByDate = newTotalFocusTimeByDate
    }
    
    func deleteSession(_ session: Session) {
        modelContext.delete(session)
        do {
            try modelContext.save()
            loadSessions()
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
    func formatTotalTime(for date: Date) -> String {
        guard let totalTime = totalFocusTimeByDate[date] else { return "0 min" }
        
        let minutes = Int(totalTime / 60)
        return "\(minutes) min"
    }
    
    func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
    }
}
