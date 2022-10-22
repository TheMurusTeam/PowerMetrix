//
//  Metrics.swift
//  it.murus.powermetrix.helper
//
//  Created by hany on 30/10/21.
//

import Foundation


/*
    TO CREATE A SINGLE POWERMETRICS REPORT AND SAVE IT TO PLIST:
 
    sudo powermetrics -s cpu_power,gpu_power,bandwidth -i 1000 -f plist -n 1 > output.plist
 
 */



// MARK: GET POWERMETRICS OUTPUT

func runPowermetrics() {
    let task = Process()
    task.launchPath = "/usr/bin/powermetrics"       // shell command
    task.arguments = ["-s","cpu_power,gpu_power",   // samplers
                      "-i","1000",                  // frequency (ms)
                      "-f","plist"                  // output format
    ]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    let outHandle = pipe.fileHandleForReading
    outHandle.waitForDataInBackgroundAndNotify()
    
    var obs1 : NSObjectProtocol!
    obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                                                  object: outHandle, queue: nil) {  notification -> Void in
        let data = outHandle.availableData
        
        if data.count > 0 {
           // send data to Powermetrix.app
                (xpchelper.connection()?.remoteObjectProxyWithErrorHandler() { error -> Void in print("XPC error: %@", error) } as? PMAgentProtocol)?.sendMetrics(metrix: data)
        
            outHandle.waitForDataInBackgroundAndNotify()
        } else {
            //print("EOF on stdout from process")
            NotificationCenter.default.removeObserver(obs1!)
        }
    }
    
    var obs2 : NSObjectProtocol!
    obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                                                  object: task, queue: nil) { notification -> Void in
        //print("terminated")
        NotificationCenter.default.removeObserver(obs2!)
    }
    task.launch()
}





