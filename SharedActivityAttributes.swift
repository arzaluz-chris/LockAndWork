//  SharedActivityAttributes.swift
//  LockAndWork
//
//  Created by Christian Arzaluz on 07/05/25.
//

import ActivityKit
import SwiftUI

// Making these public so they can be accessed from the widget extension
public struct LockAndWorkWidgetAttributes: ActivityAttributes, Codable {
    public struct ContentState: Codable, Hashable {
        public var endDate: Date
        public var blockType: BlockType
        
        public init(endDate: Date, blockType: BlockType) {
            self.endDate = endDate
            self.blockType = blockType
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
