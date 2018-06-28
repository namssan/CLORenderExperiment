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
    
    class func unitVec(p1 : CGPoint, p2 : CGPoint) -> CGPoint {
        
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let len = max(CGFloat(sqrt(len_sq(p1: p1, p2: p2))),0.0001)
        return CGPoint(x: dx / len, y: dy / len)
    }
    
    class func lenVec(p : CGPoint) -> CGFloat {
        
        let len_sq = self.len_sq(p1: .zero, p2: p)
        return CGFloat(sqrt(len_sq))
    }
    
    class func normVec(p : CGPoint) -> CGPoint {
        
        return CGPoint(x: p.y, y: -p.x)
    }
    
    class func scaleVec(p : CGPoint, scale : CGFloat, offset : CGPoint) -> CGPoint {
        
        let x = p.x * scale + offset.x + 0.1
        let y = p.y * scale + offset.y + 0.1
        
        return CGPoint(x: x, y: y)
    }
    
    class func clamp(value : CGFloat, lower : CGFloat, higher : CGFloat) -> CGFloat {
        if(value < lower) { return lower }
        if(value > higher) { return higher }
        return value
    }
}



