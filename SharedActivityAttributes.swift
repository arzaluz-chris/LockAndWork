//  SharedActivityAttributes.swift
//  LockAndWork
//
//  Created by Christian Arzaluz on 07/05/25.
//

import ActivityKit
import SwiftUI

// Only include this if you don't already have it in your main app
// Otherwise, use your existing BlockType enum
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

struct LockAndWorkWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endDate: Date
        var blockType: BlockType
    }
    
    var blockType: BlockType
}
