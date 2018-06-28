//
//  INNeonRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INNeonRender: INRenderProtocol {
    
    func createLayer(color: UIColor, width: CGFloat, renderingPath: UIBezierPath) -> CAShapeLayer {
        let layer = CAShapeLayer()
        drawLayer(at: layer, color: color, width: width, renderingPath: renderingPath)
        return layer
    }
    

    func drawLayer(at layer: CAShapeLayer, color: UIColor, width: CGFloat, renderingPath: UIBezierPath) {
        layer.lineJoin = kCALineJoinRound
        layer.lineCap = kCALineCapRound
        layer.path = renderingPath.cgPath
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = width
//        layer.cornerRadius = 8.0
        layer.shadowRadius = 5.0
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
    }
    
    func drawStroke(at ctx: CGContext, color: UIColor, width: CGFloat, renderingPath: UIBezierPath) {
        
        UIGraphicsPushContext(ctx)
        ctx.setShadow(offset: .zero, blur: 5.0, color: color.cgColor)
        ctx.setFillColor(UIColor.clear.cgColor)
        
        renderingPath.lineCapStyle = .round
        renderingPath.lineJoinStyle = .round
        renderingPath.lineWidth = width
        UIColor.white.setStroke()
        renderingPath.stroke()
        
        UIGraphicsPopContext()
    }
    
    func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint, width: CGFloat) -> UIBezierPath {
        
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
