//
//  RacerView.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//

import SwiftUI

/// An item in the racer list.
///
struct RacerView: View {
    
    var index: Int
    @ObservedObject var racer: Racer
    
    static func format(time: UInt64) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(Double(time) / 1000.00))!
    }
    
    var body: some View {
        HStack {
            if racer.disqualified {
                Text("D").background(Color.red).foregroundColor(Color.white)
            } else {
                Text("\(index + 1)")
            }
            Text("")
                .frame(minWidth: 5, maxHeight: .infinity)
                .background(racer.color)
            VStack(alignment: .leading) {
                HStack {
                    Text("\(racer.name)").fontWeight(.bold).font(.title3)
                    Spacer()
                    Text("\(racer.vehicle)").fontWeight(.bold).font(.footnote).foregroundColor(.accentColor)
                }
                if racer.lap > 0 {
                    HStack {
                        Text("Laps: \(racer.lap - 1)").font(.footnote)
                        Text("Lap Time: \(RacerView.format(time: racer.lapTime))").font(.footnote)
                        Text("Total: \(RacerView.format(time: racer.raceTime))").font(.footnote)
                    }
                }
            }
        }
    }
}

struct RacerView_Previews: PreviewProvider {
    static var previews: some View {
        let racer = Racer(id: 1, vehicle: "Audi R8", name: "Eric")
        RacerView(index: 1, racer: racer)
    }
}
