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
        }
        .padding(.vertical, 5)
    }
    
    private var timeRange: String {
        guard let endDate = session.endDate else {
            return "\(timeFormatter.string(from: session.startDate)) - ?"
        }
        
        return "\(timeFormatter.string(from: session.startDate)) - \(timeFormatter.string(from: endDate))"
    }
}

#Preview {
    SessionListItemView(
        session: Session(
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            type: .focus
        )
    )
    .padding()
}
