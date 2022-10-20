//
//  Helper.swift
//  it.murus.powermetrix.helper
//
//  Created by hany on 30/10/21.
//

import Foundation
import Cocoa



// XPC HELPER CLASS

class PMHelper: NSObject, PMHelperProtocol, NSXPCListenerDelegate{
    
    
    // MARK: Private Constant Variables
    
    private let listener: NSXPCListener
    
    
    // MARK: Private Variables
    
    private var connections = [NSXPCConnection]()
    private var shouldQuit = false
    
    
    // MARK: Initialization
    
    override init() {
        self.listener = NSXPCListener(machServiceName: "it.murus.powermetrix.helper")
        super.init()
        self.listener.delegate = self
    }
    
    public func run() {
        NSLog("starting it.murus.powermetrix.helper XPC listener")
        self.listener.resume()
        RunLoop.current.run()
    }
    
    
    // MARK: NSXPCListenerDelegate Methods
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        
        // Verify that the calling application is Snail.app
        guard PMXPCVerifier.isValid(connection: connection) else {
            NSLog("Client with PID \(connection.processIdentifier) rejected, nice try :-) ")
            return false
        }
        
        NSLog("XPC connection from process with PID \(connection.processIdentifier)")
        // Set the protocol that the calling application conforms to.
        connection.remoteObjectInterface = NSXPCInterface(with: PMAgentProtocol.self)
        // Set the protocol that the helper conforms to.
        connection.exportedInterface = NSXPCInterface(with: PMHelperProtocol.self)
        connection.exportedObject = self
        // Set the invalidation handler to remove this connection when it's work is completed.
        connection.invalidationHandler = {
            if let connectionIndex = self.connections.firstIndex(of: connection) {
                self.connections.remove(at: connectionIndex)
            }
        }
        self.connections.append(connection)
        connection.resume()
        return true
    }
    
    public func connection() -> NSXPCConnection? {
        return self.connections.last
    }
    
    
    
    
    /// Funzioni chiamate dall'app client Powermetrix.app
    /// vengono definite nel protocollo PMHelperProtocol
    
    
    // MARK: - HELPER FUNCTIONS
    
    func getVersion(reply: (String) -> Void) {
        let helperBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        NSLog("XPC QUERY: replying helper version \(helperBuild) to Powermetrix app")
        reply(helperBuild)
    }
    
    
    func quitHelper() {
        NSLog("quitting Powermetrix privileged helper tool")
        exit(0)
    }
    
    
    
}
























