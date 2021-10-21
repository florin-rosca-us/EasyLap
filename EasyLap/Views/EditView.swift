//
//  EditView.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//

import SwiftUI
import os

/// Edit one racer
///
struct EditView: View {
    
    @ObservedObject var racer: Racer
    @State var pickColor: Bool = false
    
    var body: some View {
        VStack {
            Form() {
                Section(header: Text("Info")) {
                    TextField("Name", text: $racer.name)
                    TextField("Vehicle", text: $racer.vehicle)
                    ColorPicker("Color", selection: $racer.color, supportsOpacity: false)
                }
                Section(header: Text("ID")) {
                    Text(verbatim: "\(racer.id)")
                }
                Section(header: Text("This race")) {
                    Text("Lap: \(racer.lap)")
                    Text("Lap Time: \(RacerView.format(time: racer.lapTime))")
                    Text("Total: \(RacerView.format(time:racer.raceTime))")
                }
            }
        }
        .navigationBarTitle("Racer")
        .navigationBarHidden(false)
        .onDisappear() {
            save(racer)
        }
    }
    
    private func save(_ racer: Racer) {
        RacerSerializer.shared.save(racer)
    }

}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        let racer = Racer(id: 1, vehicle: "Audi R8", name: "Eric")
        EditView(racer: racer)
    }
}
