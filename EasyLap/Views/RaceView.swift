//
//  RaceView.swift
//  EasyLap
//
//  Created by Florin on 9/28/21.
//

import SwiftUI

struct RaceView: View {
    
    @ObservedObject var race: Race
    
    var body: some View {
        if race.racers.count > 0 {
            List {
                // TODO: how to get index?
                // See https://jierong.dev/2020/05/31/foreach-with-index-in-swiftui.html
                /*
                ForEach(race.racers, id: \.id) { racer in
                    NavigationLink(destination: EditView(racer: racer)) {
                        RacerView(racer: racer)
                    }
                }.onDelete(perform: delete)
                */
                ForEach(race.racers.indices, id: \.self) { index in
                    NavigationLink(destination: EditView(racer: race.racers[index])) {
                        RacerView(index: index, racer: race.racers[index])
                    }
                }.onDelete(perform: delete)
            }.id(UUID())
        } else {
            Text("Waiting for racers to join").font(.footnote)
        }
    }
    
    private func delete(at offsets: IndexSet) {
        race.delete(at: offsets)
    }
}

struct RaceContainer: View {
    @StateObject var race = Race()
    var body: some View {
        RaceView(race: race)
    }
}
struct RaceView_Previews: PreviewProvider {
    static var previews: some View {
        RaceContainer()
    }
}
