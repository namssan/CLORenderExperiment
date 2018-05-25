//
//  INNeonRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INNeonRender: INRenderer {

    override func drawLayer(at: CAShapeLayer, renderingPath : UIBezierPath?) {
        at.lineJoin = kCALineJoinRound
        at.lineCap = kCALineCapRound
        at.path = renderingPath?.cgPath
        at.strokeColor = UIColor.white.cgColor
        at.fillColor = UIColor.clear.cgColor
        at.lineWidth = 1.0
        at.cornerRadius = 8.0
        at.shadowRadius = 2.0
        at.shadowColor = UIColor.red.cgColor
        at.shadowOpacity = 0.7
        at.shadowOffset = CGSize(width: 0.0, height: 0.0)
    }
    
    override func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint) -> UIBezierPath {
        
        let renderingPath = UIBezierPath()
        var renderCtr = 0
        var renderPts :[CGPoint] = [.zero,.zero,.zero,.zero,.zero]
        
        for (i,dot) in dots.enumerated() {
        
            let point = CGPoint(x: dot.x * scale, y: dot.y * scale)
            if(i == 0) {
                renderPts[0] = point
                continue
            }
            renderCtr += 1
            
            renderPts[renderCtr] = point
            if(renderCtr == 4) {
                
                renderPts[3] = INRenderUtils.middlePoint(p1: renderPts[2], p2: renderPts[4])
                
                renderingPath.move(to: renderPts[0])
                renderingPath.addCurve(to: renderPts[3], controlPoint1: renderPts[1], controlPoint2: renderPts[2])
                
                renderPts[0] = renderPts[3]
                renderPts[1] = renderPts[4]
                renderCtr = 1
            }
        }
        return renderingPath
    }
    
}
