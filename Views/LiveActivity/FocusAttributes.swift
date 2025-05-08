//  FocusAttributes.swift
import Foundation
import ActivityKit

struct FocusAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endDate: Date
        var blockType: BlockType
    }
    
    var blockType: BlockType
}
