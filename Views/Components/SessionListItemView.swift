//  SessionListItemView.swift
import SwiftUI

struct SessionListItemView: View {
    var session: Session
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            // Type indicator
            Circle()
                .fill(session.type == .focus ? Color.blue : Color.green)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(timeRange)
                    .font(.callout)
                    
                Text(session.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(session.durationInMinutes) min")
                .font(.callout)
                .foregroundColor(session.type == .focus ? .blue : .green)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .accessibilityLabel("\(session.type.displayName) session, \(session.durationInMinutes) minutes, at \(timeFormatter.string(from: session.startDate))")
    }
    
    private var timeRange: String {
        guard let endDate = session.endDate else {
            return "\(timeFormatter.string(from: session.startDate)) - ?"
        }
        
        return "\(timeFormatter.string(from: session.startDate)) - \(timeFormatter.string(from: endDate))"
    }
}
