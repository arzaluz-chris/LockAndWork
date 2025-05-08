//  BlockType.swift
import Foundation

enum BlockType: Int, Codable, CaseIterable {
    case focus
    case `break`
    
    var displayName: String {
        switch self {
        case .focus:
            return String(localized: "Focus")
        case .break:
            return String(localized: "Break")
        }
    }
    
    var next: BlockType {
        switch self {
        case .focus:
            return .break
        case .break:
            return .focus
        }
    }
}
