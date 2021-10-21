//
//  Racer.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//

import Foundation
import SwiftUI
import os

class Racer: ObservableObject {
     
    @Published var id: UInt
    @Published var vehicle: String
    @Published var name: String
    
    var started: UInt64 = 0 // time of joining the race (absolute)
    var lastSeen: UInt64 = 0 // last seen (absolute)

    @Published var lap: UInt16 = 0 // current lap
    @Published var lapTime: UInt64 = 0 // last lap time
    @Published var raceTime: UInt64 = 0 // total time since the race started
    @Published var disqualified = false // true if passed start before race started
    @Published var color: Color
    
    /// Creates a new instance.
    ///
    init(id: UInt, vehicle: String, name: String) {
        self.id = id
        self.vehicle = vehicle
        self.name = name
        self.color = Color.red
        reset()
    }
    
    /// Resets all counters and timers.
    ///
    func reset() {
        os_log("Racer: reset")
        started = 0
        lastSeen = 0
        lap = 0
        lapTime = 0
        raceTime = 0
        disqualified = false
    }
    
    func passStart(at time: UInt64) {
        os_log(.debug, "Racer: pasStart at=\(time)")
        if lastSeen == 0 { // just passed the start line for the first time
            started = time
            raceTime = 0
            lap = 1 // current lap
        }
        else {
            lap += 1
            lapTime = time - lastSeen
            raceTime = time - started
        }
        lastSeen = time
    }
    
    /// Disqualify if passed start line before the race started.
    ///
    func disqualify(at time: UInt64) {
        os_log(.debug, "Racer: disqualify at=\(time)")
        disqualified = true
        lastSeen = time
    }
}
