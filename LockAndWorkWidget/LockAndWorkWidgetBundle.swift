//  LockAndWorkWidgetBundle.swift
//  LockAndWorkWidget
//
//  Created by Christian Arzaluz on 07/05/25.
//

import WidgetKit
import SwiftUI

@main
struct LockAndWorkWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Removed the standard widget if you don't need it
        LockAndWorkWidgetLiveActivity()
    }
}
