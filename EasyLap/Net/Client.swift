//
//  Client.swift
//  EasyLap
//
//  Created by Florin on 9/18/21.
//

import Foundation
import Network
import os

class Client: ObservableObject {
    
    // Messages sent to server
    static let msgHello = "HELLO"
    static let msgBye = "BYE"
    static let msgLightsOn = "LIGHTS ON"
    static let msgLightsOff = "LIGHTS OFF"
    static func msgLights(value: Int) -> String {
        return "LIGHTS \(value)"
    }
    
    let type: String
    let domain: String?
    
    var onError: ((NWError) -> Void)?
    var onReceived: ((Data) -> Void)?

    private var browser: NWBrowser? = nil
    
    @Published private(set) public var endpoint: NWEndpoint?
    
    private var connection: NWConnection?
    private var cancelled = false
    private var timer: Timer?
    
    
    /// Creates a new instance.
    ///
    init(type: String = "_easylap._udp", domain: String? = nil) {
        self.type = type
        self.domain = domain
        // DO NOT START HERE, call start() on appear
    }
    
    /// Starts the client.
    ///
    func start() -> Void {
        os_log(.debug, "Client: start")
        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: type, domain: domain), using: params)
        browser!.browseResultsChangedHandler = { results, changes in
            for change in changes {
                switch change {
                case .added(let browseResult):
                    switch browseResult.endpoint {
                    case .service(let name, let type, let domain, let interface):
                        os_log(.info, "Client: added \(name) \(type) \(domain) \(String(describing: interface))")
                        self.added(endpoint: browseResult.endpoint)
                        self.endpoint = browseResult.endpoint
                    default:
                        // Found something else than a service. What can that be?
                        os_log(.error, "Client: failed to find service")
                        // TODO: Error?
                        self.endpoint = nil
                    }
                case .removed(let browseResult):
                    os_log(.info, "Client: removed \(String(describing: browseResult))")
                    self.endpoint = nil
                case .changed(_, let browseResult, let flags):
                    os_log(.info, "Client: changed \(String(describing:browseResult)) \(String(describing:flags))")
                default:
                    // print("No change")
                    break
                }
            }
        }
        browser!.stateUpdateHandler = { state in
            switch  state {
            case .ready:
                break
            case .failed(let error):
                os_log(.error, "error: %@", "\(error)")
                self.onError?(error)
            default:
                break
            }
            // print(state)
        }
        browser!.start(queue: .main)
        cancelled = false
    }
    
    
    private func added(endpoint: NWEndpoint) {
        os_log(.debug, "added endpoint: %@", "\(endpoint)")
        let udpOption = NWProtocolUDP.Options()
        let params = NWParameters(dtls: nil, udp: udpOption)
        // The server works only on IPv4
        // Force IPv4 from https://stackoverflow.com/questions/64102383/nwconnection-timeout
        if let isOption = params.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            isOption.version = .v4
        }
        params.allowLocalEndpointReuse = true // Meh, why?
        let connection = NWConnection(to: endpoint, using: params) // Discovered browsing endPoint
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("connected to \(connection.endpoint)")
                print(connection.currentPath?.remoteEndpoint ?? "error")
                print(connection.parameters)
                self.send(to: connection, message: Client.msgHello)
                self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
                    self.send(to: connection, message: Client.msgHello)
                }
            case .failed(let error):
                os_log(.error, "error: %@", "\(error)")
                self.cancel()
                self.onError?(error)
            default:
                break
            }
        }
        self.receive(from: connection)
        self.connection = connection
        connection.start(queue: .main)
    }
    
    
    func send(message: String) {
        os_log(.debug, "Client: send")
        guard let connection = self.connection else {
            os_log(.error, "Client: send: no connection")
            return
        }
        self.send(to: connection, message: message)
    }
    
    
    private func send(to connection: NWConnection, message: String) {
        if cancelled {
            return
        }
        let data = Data(message.utf8)
        connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed { error in
            if let error = error {
                os_log(.error, "Client: did send, error: %@", "\(error)")
                self.cancel()
                self.onError?(error)
            }
            /*else {
                os_log(.debug, "Did send, data: %@", data as NSData)
            }*/
        })
    }
    
    
    private func receive(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isDone, error in
            if let data = data, !data.isEmpty {
                os_log(.debug, "Client: received")
                self.onReceived?(data)
            }
            if let error = error {
                os_log(.error, "Client: error: %@", "\(error)")
                self.cancel()
                self.onError?(error)
                return // TODO: error handler?
            }
            if !isDone {
                os_log(.error, "Client: did not receive the entire message, now what?")
                return // TODO: then what?
            }
            self.receive(from: connection) // enter recursivity (BLAH)
        }
    }
        
    /// Cancels the browser and the connection. The client cannot be used after calling this.
    ///
    func cancel() {
        os_log(.debug, "Client: cancel")
        self.cancelled = true
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        if connection != nil {
            connection!.cancel()
            connection = nil
        }
        if browser != nil && [NWBrowser.State.setup, NWBrowser.State.ready].contains(browser!.state) {
            browser!.cancel()
        }
    }

    
    func restart() -> Void {
        os_log(.debug, "Client: restart")
        cancel()
        start()
    }

}
