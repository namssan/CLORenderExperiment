//
//  INDot.swift
//  IdeaNotes
//
//  Created by Sang Nam on 5/1/17.
//  Copyright © 2017 Sang Nam. All rights reserved.
//

import UIKit

class INDot: NSObject {

    var x : CGFloat
    var y : CGFloat
    var p : CGFloat
    var t : TimeInterval
    

    init(point : CGPoint, pressure : CGFloat) {
        x = point.x
        y = point.y
        p = pressure
        t = Date().timeIntervalSince1970 * 1000
        
        super.init()
    }
    
    init(point : CGPoint, pressure : CGFloat, time : TimeInterval) {
        x = point.x
        y = point.y
        p = pressure
        t = time
        
        super.init()
    }
    
    func point() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}
