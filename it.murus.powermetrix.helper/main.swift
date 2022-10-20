//
//  main.swift
//  it.murus.powermetrix.helper
//
//  Created by hany on 29/10/21.
//


// POWERMETRIX PRIVILEGED HELPER TOOL


import Foundation
NSLog("starting it.murus.powermetrix.helper")
let xpchelper = PMHelper()
DispatchQueue.global().async { xpchelper.run() }
runPowermetrics()
CFRunLoopRun()

