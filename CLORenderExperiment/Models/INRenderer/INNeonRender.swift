//
//  INNeonRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INNeonRender: INRenderProtocol {

    func createLayer(renderingPath : UIBezierPath) -> INShapeLayer {
        
        let layer = INShapeLayer()
        layer.lineJoin = kCALineJoinRound
        layer.lineCap = kCALineCapRound
        layer.path = renderingPath.cgPath
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 6.0
        layer.cornerRadius = 8.0
        layer.shadowRadius = 2.0
        layer.shadowColor = UIColor.red.cgColor
        layer.shadowOpacity = 0.7
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        return layer
    }
    
    func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint) -> UIBezierPath {
        
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
                
                let x = (renderPts[2].x + renderPts[4].x)/2.0
                let y = (renderPts[2].y + renderPts[4].y)/2.0
                renderPts[3] = CGPoint(x: x, y: y)
                
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
