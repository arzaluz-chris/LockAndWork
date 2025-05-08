//  SharedActivityAttributes.swift
//  LockAndWork
//
//  Created by Christian Arzaluz on 07/05/25.
//

import ActivityKit
import SwiftUI

// Making these public so they can be accessed from the widget extension
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

struct LockAndWorkWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var blockType: BlockType
    }
    
    var blockType: BlockType
}
