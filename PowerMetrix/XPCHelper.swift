//
//  XPCHelper.swift
//  PowerMetrix
//
//  Created by hany on 29/10/21.
//


// XPC CLIENT CLASS


import Foundation
import Cocoa


class PMHelper : NSObject, PMAgentProtocol {
    
    
    // MARK: INIT
    
    override init() {
        super.init()
    }
    
    // MARK: HELPER CONNECTION
    
    private var currentHelperConnection: NSXPCConnection?
    
    func helperConnection() -> NSXPCConnection? {
        guard self.currentHelperConnection == nil else {
            return self.currentHelperConnection
        }
        let connection = NSXPCConnection(machServiceName: "it.murus.powermetrix.helper",
                                         options: .privileged)
        connection.exportedInterface = NSXPCInterface(with: PMAgentProtocol.self)
        connection.exportedObject = self
        connection.remoteObjectInterface = NSXPCInterface(with: PMHelperProtocol.self)
        connection.invalidationHandler = {
            self.currentHelperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.currentHelperConnection = nil
            }
        }
        self.currentHelperConnection = connection
        self.currentHelperConnection?.resume()
        return self.currentHelperConnection
    }
    
    // MARK: HELPER FUNCTIONS
    var message = ""
    
    func sendMetrics(metrix: Data) {
        //print("received metrix from helper")
        if let str = String(data: metrix, encoding: String.Encoding.ascii) {
            //print(metrix)
            if str.contains("</plist>") {
                self.message = message + str
                var test = message.components(separatedBy: "\n")
                test.removeFirst()
                self.message = test.joined()
               // print("###start")
                
                if let mydata = self.message.data(using: .utf8) {
                    do {
                        
                        let metrix = try PropertyListSerialization.propertyList(from: mydata, format: nil) as! Dictionary< String, AnyObject>
                        insertNewMetrics(newmetrix: metrix)
                        // menulet
                        DispatchQueue.main.async {
                            (NSApplication.shared.delegate as! AppDelegate).displayMenuletMetrics(metrix: metrix)
                        }
                        // window
                        DispatchQueue.main.async {
                            (pmWindows["main"] as? PMMainWindowController)?.updateGUI()
                        }
                        
                        
                    }catch {}
                }
                self.message = ""
              //  print("###end")
            } else {
                self.message = self.message + str
            }
        }
        
    }
    
    
}
