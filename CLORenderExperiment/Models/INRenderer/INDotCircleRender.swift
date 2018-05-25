//
//  INDotCircleRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 24/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INDotCircleRender: INRenderer {
    
    
    override func drawLayer(at: CAShapeLayer, renderingPath : UIBezierPath?) {
        
    }
    override func createLayer(renderingPath : UIBezierPath) -> INShapeLayer {
        
        let layer = INShapeLayer()
        layer.lineJoin = kCALineJoinRound
        layer.lineCap = kCALineCapRound
        layer.path = renderingPath.cgPath
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = UIColor.black.cgColor
        layer.shadowColor = UIColor.clear.cgColor
        layer.lineWidth = 0.2
        layer.opacity = 0.5
        
        return layer
    }
    
    override func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint) -> UIBezierPath {
        
        print("print render dot: \(dots.count)")
        let treashold = (3.0 / scale)
        let renderingPath = UIBezierPath()
        for (i,dot) in dots.enumerated() {
            
            let point = CGPoint(x: dot.x * scale, y: dot.y * scale)
            let len = 15.0 * dot.p
            let rect = CGRect(x: point.x, y: point.y, width: len, height: len)
            let subPath = UIBezierPath(rect: rect)
            renderingPath.append(subPath)
            
            if i > 0 {
                let prvDot = dots[i-1]
                let dx = dot.x - prvDot.x
                let dy = dot.y - prvDot.y
                let dp = (dot.p - prvDot.p) * 15.0
                let dlen = sqrt(INRenderUtils.len_sq(p1: prvDot.point, p2: dot.point))
                if dlen > treashold {
                    let steps = Int(dlen / (treashold / 10.0))
                    print("too far :\(dlen) ---> steps: \(steps)")
                    let dxx = dx / CGFloat(steps)
                    let dyy = dy / CGFloat(steps)
                    let dpp = dp / CGFloat(steps)
                    
                    for i in 1...steps {
                        let slen = (prvDot.p * 15.0) + (dpp * CGFloat(i))
                        let nx = (prvDot.x + (dxx * CGFloat(i))) * scale
                        let ny = (prvDot.y + (dyy * CGFloat(i))) * scale
                        let rect = CGRect(x: nx, y: ny, width: slen, height: slen)
                        let subPath = UIBezierPath(rect: rect)//UIBezierPath(ovalIn: )
                        renderingPath.append(subPath)
                    }
                }
                
            }
        }
        return renderingPath
    }
}
