//
//  EasyLapApp.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//

import SwiftUI
import os

@main
struct EasyLapApp: App {
    
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
        os_log("EasyLap starting")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
