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
    
    var point : CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }

    init(point : CGPoint, pressure : CGFloat) {
        x = point.x
        y = point.y
        p = max(pressure, 0.01)
        t = Date().timeIntervalSince1970 * 1000
        
        super.init()
    }
    
    init(point : CGPoint, pressure : CGFloat, time : TimeInterval) {
        x = point.x
        y = point.y
        p = max(pressure, 0.01)
        t = time
        
        super.init()
    }
    

}
