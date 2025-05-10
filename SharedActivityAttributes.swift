//  SharedActivityAttributes.swift
import ActivityKit
import SwiftUI

// Public attributes for the Live Activity
public struct LockAndWorkWidgetAttributes: ActivityAttributes, Codable {
    public struct ContentState: Codable, Hashable {
        // End date represents when the timer will finish
        public var endDate: Date
        public var blockType: BlockType
        
        public init(endDate: Date, blockType: BlockType) {
            self.endDate = endDate
            self.blockType = blockType
        }
        
        // Helper function to get the timer interval for display
        public func getTimerInterval() -> ClosedRange<Date> {
            return endDate...endDate
        }
    }
    
    public var blockType: BlockType
    
    public init(blockType: BlockType) {
        self.blockType = blockType
    }
}

// Public enum for block types to be shared between main app and widget
public enum BlockType: Int, Codable, CaseIterable {
    case focus
    case `break`
    
    public var displayName: String {
        switch self {
        case .focus:
            return String(localized: "Focus")
        case .break:
            return String(localized: "Break")
        }
    }
    
    public var next: BlockType {
        switch self {
        case .focus:
            return .break
        case .break:
            return .focus
        }
    }
}
