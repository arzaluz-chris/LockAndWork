//  CircularProgressView.swift
import SwiftUI

struct CircularProgressView: View {
    var progress: Double
    var strokeWidth: CGFloat = 8
    var backgroundColor: Color = Color(.systemGray5)
    var foregroundColor: Color = Color.accentColor
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: strokeWidth)
            
            // Foreground circle
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
}

#Preview {
    CircularProgressView(progress: 0.7)
        .frame(width: 200, height: 200)
        .padding()
}
