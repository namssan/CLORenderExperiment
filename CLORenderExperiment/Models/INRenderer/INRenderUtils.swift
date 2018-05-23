//
//  INRenderUtils.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INRenderUtils: NSObject {

    class func len_sq(p1 : CGPoint, p2 : CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return (dx * dx + dy * dy)
    }
    
    class func middlePoint(p1 : CGPoint, p2 : CGPoint) -> CGPoint {
        let x = (p1.x + p2.x)/2.0
        let y = (p1.y + p2.y)/2.0
        return CGPoint(x: x, y: y)
    }
    
    class func clamp(value : CGFloat, lower : CGFloat, higher : CGFloat) -> CGFloat {
        if(value < lower) { return lower }
        if(value > higher) { return higher }
        return value
    }
}
