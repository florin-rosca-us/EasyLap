//
//  ContentView.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//  See https://developer.apple.com/tutorials/swiftui/building-lists-and-navigation
//  See https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-environmentobject-to-share-data-between-views
//  See https://www.hackingwithswift.com/quick-start/swiftui/enabling-and-disabling-elements-in-forms
//
//  FIXME: toolbar buttons are not responsive.
//  See https://stackoverflow.com/questions/63540602/navigationbar-toolbar-button-not-working-reliable-when-state-variable-refres

import SwiftUI
import Network
import os

struct ContentView: View {
    
    static let KEY_TIME = "time"
    static let KEY_UID = "uid"
    
    // Background/foreground
    @Environment(\.scenePhase) var scenePhase
    
    // Network stuff
    enum NetStat {
        case ok
        case notConnected
        case error
    }
    @StateObject var client = Client()
    @State var netStat: NetStat = .notConnected
    
    // Race
    @StateObject var race = Race()
    
    @State var countdownTimer: Timer? // countdown to race start
    @State var countdownCount: Int = 0 // countdown to race start
    
    // Other
    @State var setup: Bool = false // shpw or hide the Setup sheet
    @State var raceCount: UInt = 0 // counting how many races were started
    
    init() {
    }
    
    var body: some View {
        NavigationView {
            VStack {
                RaceView(race: race)
            }.navigationBarTitle(title)
            .navigationBarHidden(false)
        }
        .onAppear {
            let twoLights = Client.msgLights(value: (1<<3) + (1<<5))
            client.onError = self.onError(error:)
            client.onReceived = self.onReceived(data:)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in 
                client.start()
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {_ in
                    client.send(message: twoLights)
                }
            }
            race.onStateUpdated = { oldValue, newValue in
                switch newValue {
                case .stopped:
                    client.send(message: twoLights)
                case .started:
                    client.send(message: Client.msgLightsOff)
                default:
                    break
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                switch race.state {
                case .stopped:
                    Button(raceCount == 0 ? "Start" : "New") {
                        race.reset()
                        startCountdown()
                    }
                    .disabled(race.racers.count == 0)
                case .starting:
                    Button("Cancel") {
                        countdownTimer?.invalidate()
                        race.state = .stopped
                    }
                case .started:
                    Button("Pause") {
                        race.state = .paused
                    }
                    Button("Stop") {
                        race.state = .stopped
                        raceCount += 1
                    }
                case .paused:
                    Button("Continue") {
                        race.state = .started
                    }
                    Button("Stop") {
                        race.state = .stopped
                    }
                }
                Spacer()
                Button(action: { self.setup = true }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $setup) {
            // The netstat image blinks when receiving data from server. Blinking refreshes the entire UI and makes
            // tapping buttons harder. Moving the netstat image to a modal sheet should fix the issue.
            //
            NavigationView {
                SetupView(client: client)
                    .navigationBarItems(leading: Image(netStatImage), trailing: Button("Done", action: { self.setup = false}))
            }
        }
        .onChange(of: scenePhase, perform: { newPhase in
            switch newPhase {
            case .inactive:
                os_log(.debug, "inactive")
                if race.state == .started {
                    race.state = .paused
                }
                client.cancel()
            case .active:
                os_log(.debug, "active")
                client.restart()
            case .background:
                os_log(.debug, "background")
                client.cancel()
            default:
                break
            }
        })
    }
    
    /// Deletes a racer from the list at the specified index(es).
    ///
    private func delete(at offsets: IndexSet) {
        race.delete(at: offsets)
    }
    
    private var title: String {
        get {
            switch race.state {
            case .stopped:
                return "Race"
            case .paused:
                return "Race Paused"
            case .starting:
                if countdownCount > 0 {
                    return "Race Starting in \(countdownCount)" // actually, this is countdown
                }
                else {
                    return "Race Starting"
                }
            case .started:
                return "Race Started"
            }
        }
    }
    
    /// The netstat image.
    ///
    private var netStatImage: String {
        get {
            switch netStat {
            case .error:
                return "NetStatError"
            case .notConnected:
                return "NetStatNotConnected"
            case .ok:
                return "NetStatOK"
            }
        }
    }
    
    /// Called when data is received.
    ///
    private func onReceived(data: Data) {
        let jsonObj = try? JSONSerialization.jsonObject(with: data, options: [])
        if let dict = jsonObj as? [String: Any] {
            let time = dict[ContentView.KEY_TIME] as? UInt64 ?? 0
            let id = dict[ContentView.KEY_UID] as? UInt ?? 0
            let _ = race.time(id: id, at: time)
            // Blink connection indicator
            netStat = .ok
            let _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
                netStat = .notConnected
                // TODO: .error ???
            }
        }
    }
    
    /// Called when an error is received.
    ///
    private func onError(error: NWError) {
        race.state = .stopped
    }
    
    /// Starts the countdown to race start.
    ///
    private func startCountdown() {
        var values: [Int] = []
        for i in [1,2,3,4,5] {
            values.append((values.last ?? 0) + (1 << i))
        }
        self.countdownCount = 0
        race.state = .starting
        client.send(message: Client.msgLightsOff)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.countdownCount == 0 {
                self.countdownCount = 5
            }
            else {
                self.countdownCount -= 1
            }
            
            if self.countdownCount > 0 {
                client.send(message: Client.msgLights(value: values[5 - self.countdownCount]))
            }
            else {
                timer.invalidate()
                let randTime = Int.random(in: 0...3)
                countdownTimer = Timer.scheduledTimer(withTimeInterval: Double(randTime), repeats: false) { timer in
                    race.state = .started
                }
            }
        }
    }
}

/// Preview.
///
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
