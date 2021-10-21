//
//  Race.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//

import Foundation
import os

enum RaceState {
    case stopped
    case starting
    case started
    case paused
}

/// A race.
///
class Race: ObservableObject {

    var onStateUpdated: ((RaceState, RaceState) -> Void)? = nil // called when the state changed
    var lastUpdated: UInt64 = 0 // timestamp
    @Published var racers: [Racer] = [] // all racers
    @Published var state: RaceState = .stopped { // the state
        didSet {
            if oldValue != state {
                onStateUpdated?(oldValue, state)
            }
        }
    }
    
    /// Creates a new instance.
    ///
    init(stateUpdated: ((RaceState, RaceState) -> Void)? = nil) {
        self.onStateUpdated = stateUpdated
    }
    
    /// Adds a racer.
    ///
    private func add(racer id: UInt) -> Racer? {
        os_log(.debug, "Race: add id=\(id)")
        if id == 0 {
            return nil
        }
        guard let existing = racers.first(where: {$0.id == id}) else {
            var added = Racer(id: id, vehicle: "\(id)", name: "New Racer")
            RacerSerializer.shared.load(id: id, racer: &added)
            racers.append(added)
            return added
        }
        return existing
    }
    
    /// Returns a racer by ID.
    ///
    func get(racer id: UInt) -> Racer? {
        return racers.first(where: {$0.id == id})
    }
    
    /// Sorts the list of racers.
    ///
    private func sort() {
        os_log(.debug, "Race: sort")
        // areInIncreasingOrderL A predicate that returns true if its first argument should be ordered before its second argument
        racers.sort { r1, r2 in
            if r1.disqualified && r2.disqualified {
                return r1.raceTime < r2.raceTime
            }
            else if r1.disqualified {
                return false
            }
            else if r2.disqualified {
                return true
            }
            else if r1.lap > r2.lap {
                return true
            }
            else if r1.lap == r2.lap {
                return r1.raceTime < r2.raceTime
            }
            return true
        }
    }
    
    
    /// Updates timers during the race.
    ///
    /// - Parameter racer: The racer ID.
    /// - Parameter time: The current time.
    ///
    private func update(racer id: UInt, at time: UInt64) -> Racer? {
        os_log(.debug, "Race: update id=\(id) time=\(time)")
        // objectWillChange.send()
        guard let racer = get(racer: id) else {
            if id == 0 { // only if this is a timing packet, do not update when receiving an ID
                for r in racers { // time tick, update race time for all racers
                    if r.started > 0 {
                        r.raceTime = time - r.started
                    }
                }
            }
            sort()
            return nil
        }
        if time - racer.lastSeen < 1 {
            os_log(.info, "Race: seen too often")
            return racer
        }
        racer.passStart(at: time)
        sort()
        return racer
    }
    
    /// Called when the racer with the specified ID passes the start/finish line or when a timing packet was received.
    ///
    func time(id: UInt, at time: UInt64) -> Racer? {
        os_log(.debug, "Race: time=\(time) id=\(id)")
        if time <= 0 {
            return nil
        }
        else if time < lastUpdated { // When the USB connector is removed then connected back
            os_log(.error, "Received bad time: lastUpdated=\(self.lastUpdated) time=\(time)")
            state = .stopped
            return nil
        }
        lastUpdated = time
        
        switch state {
        case .stopped:
            if id != 0 {
                return add(racer: id)
            }
            break
        case .starting:
            if id != 0 {
                guard let racer = get(racer: id) else { return nil }
                racer.passStart(at: time)
                racer.disqualify(at: time)
                sort()
                return racer
            }
            break
        case .started:
            return update(racer: id, at: time)
        case .paused:
            break
        }
        return nil
    }
    
    func reset() {
        lastUpdated = 0
        for r in racers {
            r.reset()
        }
    }
    
    /// Deletes a racer from the race.
    ///
    func delete(at offsets: IndexSet) {
        os_log(.debug, "Race: delete")
        racers.remove(atOffsets: offsets)
    }
    
    func addTestRacers() {
        var r1 = Racer(id: 1, vehicle: "Vehicle 1", name: "Racer 1")
        RacerSerializer.shared.load(id: 1, racer: &r1)
        racers.append(r1)
        
        var r2 = Racer(id: 2, vehicle: "Vehicle 2", name: "Racer 2")
        RacerSerializer.shared.load(id: 2, racer: &r2)
        racers.append(r2)
    }
}
