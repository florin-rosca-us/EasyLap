//
//  SetupView.swift
//  EasyLap
//
//  Created by Florin on 9/30/21.
//

import SwiftUI

struct SetupView: View {
    
    @ObservedObject var client: Client
    
    var body: some View {
        VStack {
            Form() {
                Section(header: Text("Client")) {
                    Text("Type: \(client.type)")
                    Text("Domain: \(client.domain ?? "")")
                    Text("Endpoint: \(client.endpoint != nil ? String(describing: client.endpoint!) : "")")
                }
            }
            HStack {
            }
        }.toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {client.send(message: Client.msgLightsOn)}) {
                    Image(systemName: "lightbulb.fill")
                    Text("Lights On")
                }
                Button(action: {client.send(message: Client.msgLightsOff)}) {
                    Image(systemName: "lightbulb")
                    Text("Lights Off")
                }
            }
        }
        .navigationBarTitle("Setup")
        .navigationBarHidden(false)
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(client: Client())
    }
}
