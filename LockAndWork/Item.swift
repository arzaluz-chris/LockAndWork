//
//  Item.swift
//  LockAndWork
//
//  Created by Christian Arzaluz on 06/05/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
