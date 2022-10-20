//
//  Graph.swift
//  PowerMetrix
//
//  Created by hany on 30/10/21.
//

import Foundation
import Cocoa


class PMGraph: NSView {

    var framesize = CGSize()
    var array  = [Double]()
    var color = NSColor()
    
    // MARK: INIT
    
    convenience init(frame frameRect: NSRect,
                     name:String,
                     array:[Double],
                     color:NSColor?) {
        
        self.init(frame: frameRect)
        self.array = array
        self.framesize = self.frame.size
        self.color = color ?? NSColor.systemRed
    }
    
    // MARK: DRAW
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.drawGraph()
    }
    
    // MARK: GRAPH
    
    func drawGraph() {
        /*let arrayset = Set(arrayData)
        let arraymax = (arrayset.max() ?? 0.0*/
        let arraymax = (self.window?.windowController as? PMMainWindowController)?.max_packageEnergy ?? 0
        let columnWidth : CGFloat = framesize.width / CGFloat(max_metrics)
        let linePath = NSBezierPath()
        var i : Double = 0
        var x = Double()
        var y = Double()
        for column in array {
            let height : CGFloat = (framesize.height / CGFloat(arraymax)) * CGFloat(column)
            if i > 0 {
                linePath.move(to: CGPoint(x:x, y:y))
                linePath.line(to: CGPoint(x:i, y:Double(height)))
            }
            x = i
            y = Double(height)
            i = i + Double(columnWidth)
        }
        linePath.close()
        self.color.set()
        linePath.lineWidth = 1
        linePath.stroke()
    }
    
    
}




class PMRing: NSView {

   // var path = NSBezierPath()
    
    // MARK: INIT
    
    var diameter = Double()
    var max = Double()
    var value = Double()
    var color = NSColor()
    convenience init(frame frameRect: NSRect,
                     name:String,
                     max:Double,
                     value:Double,
                     color:NSColor) {
        
        self.init(frame: frameRect)
        self.diameter = frameRect.height
        self.max = max
        self.value = value
        self.color = color
      
    }
    
    // MARK: DRAW
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.drawGraph()
    }
    
    // MARK: GRAPH
    
    func drawGraph() {
        let colorCircle = self.color
        let colorPie = NSColor.controlBackgroundColor
    
        let radius = (self.frame.size.width / 2.0) - 10
        let pathCirle = NSBezierPath()
        let centerCircle = CGPoint(x:  self.frame.midX, y: self.frame.midY)
        pathCirle.appendArc(withCenter: centerCircle, radius: radius,
                                                 startAngle: 0, endAngle: 360  )
        pathCirle.lineWidth = 9
        colorCircle.set()
        pathCirle.stroke()
        
        // 360:max=x:value
    
        let path = NSBezierPath()
        let center = CGPoint(x:  self.frame.midX, y: self.frame.midY)
        let angleused = Double(360 * self.value / self.max)
        let anglecovered = 360 - angleused
        
        path.appendArc(withCenter: center, radius: radius,
                                                 startAngle: -90, endAngle: -90  + anglecovered)
        path.lineWidth = 10
        colorPie.set()
        path.stroke()
    }
    
    
}
