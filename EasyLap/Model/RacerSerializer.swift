//
//  RacerSerializer.swift
//  EasyLap
//
//  Created by Florin on 10/1/21.
//

import SwiftUI
import os

/// Serializes racers.
/// TODO: any better idea than saving to user defaults?
///
class RacerSerializer {
    
    static let shared = RacerSerializer()
    
    func save(_ racer: Racer) {
        os_log(.debug, "RacerSerializer: saving racer \(racer.id)")
        let defaults = UserDefaults.standard
        defaults.set(racer.name, forKey: "\(racer.id).name")
        defaults.set(racer.vehicle, forKey: "\(racer.id).vehicle")
        do {
            let color = UIColor(racer.color)
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
            defaults.set(data, forKey: "\(racer.id).color")
        } catch {
            os_log(.error, "cannot save color")
        }
    }
    
    func load(id: UInt, racer: inout Racer) {
        os_log(.debug, "RacerSerializer: loading racer \(id)")
        let defaults = UserDefaults.standard
        if let name = defaults.string(forKey: "\(racer.id).name") {
            racer.name = name
        }
        if let vehicle = defaults.string(forKey: "\(racer.id).vehicle") {
            racer.vehicle = vehicle
        }
        do {
            if let colorData = defaults.data(forKey: "\(racer.id).color") {
                if let uiColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
                    racer.color = Color(uiColor)
                }
            }
        } catch {
            os_log(.error, "RacerSerializer: error setting color")
        }
    }
    
    func reset() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
