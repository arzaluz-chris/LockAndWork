//  NextBlockInfoView.swift
import SwiftUI

struct NextBlockInfoView: View {
    var blockType: BlockType
    var duration: Int
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Next: \(blockType.displayName) - \(duration) min")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .accessibilityLabel("Next up is \(blockType.displayName) for \(duration) minutes")
    }
}

#Preview {
    NextBlockInfoView(blockType: .break, duration: 5)
        .padding()
}
