//
//  Metrics Store.swift
//  PowerMetrix
//
//  Created by hany on 30/10/21.
//

import Foundation

let max_metrics = 10 // numero di colonne nei grafici
var pmWindows = [String:AnyObject]()

// STORE

var metrics = [[String:AnyObject]]()

func insertNewMetrics(newmetrix:[String:AnyObject]) {
    if metrics.count > max_metrics + 1 {
        metrics.remove(at: 0)
    }
    metrics.append(newmetrix)
}
