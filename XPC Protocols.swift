//
//  XPC Protocols.swift
//  PowerMetrix
//
//  Created by hany on 30/10/21.
//

import Foundation

// AGENT PROTOCOL

@objc(PMAgentProtocol)
protocol PMAgentProtocol {
    func sendMetrics(metrix:Data) -> Void
}

// HELPER PROTOCOL
    
@objc(PMHelperProtocol)
protocol PMHelperProtocol {
    func getVersion(reply: @escaping (String) -> Void)
    func quitHelper() -> Void
}
