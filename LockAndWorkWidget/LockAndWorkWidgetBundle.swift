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
        LockAndWorkWidget()  // Add back the standard widget
        LockAndWorkWidgetLiveActivity()
    }
}
