//
//  INFountainRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INFountainRender: INRenderer {

    struct LineSegment {
        var point1 : CGPoint = .zero
        var point2 : CGPoint = .zero
        
        init(p1 : CGPoint, p2 : CGPoint) {
            self.point1 = p1
            self.point2 = p2
        }
    }
    
    
    private var renderPts :[CGPoint] = [.zero,.zero,.zero,.zero,.zero]
    private var renderCtr = 0
    private var isFirstTouchPoint = true
    private var lastSegmentOfPrev : LineSegment!
    private var lineSegments : [LineSegment] = []
    
    private var FF : CGFloat = 0.3
    private var LOWER : CGFloat = 0.01
    private var UPPER : CGFloat = 1.0
    
    func updateValues(ff : CGFloat?, lw : CGFloat?, up : CGFloat?) {
        
        if let ffv = ff { self.FF = ffv }
        if let lwv = lw { self.LOWER = lwv }
        if let upv = up { self.UPPER = upv }
    }
    
    
    override func configureLayer(layer: CAShapeLayer, renderingPath : UIBezierPath?) {
        layer.lineJoin = kCALineJoinRound
        layer.lineCap = kCALineCapRound
        layer.path = renderingPath?.cgPath
        layer.fillColor = UIColor.black.cgColor
        layer.shadowColor = UIColor.clear.cgColor
        layer.lineWidth = 0.1
        layer.strokeColor = UIColor.black.cgColor
    }
    
    
    override func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint) -> UIBezierPath {
        
        let renderingPath = UIBezierPath()
        
        isFirstTouchPoint = true
        renderPts = [.zero,.zero,.zero,.zero,.zero]
        renderCtr = 0
        
        var ls = Array<LineSegment>(repeating: LineSegment(p1: .zero,p2: .zero), count: 4)
        for (i,dot) in dots.enumerated() {
            
            let point = CGPoint(x: dot.x * scale, y: dot.y * scale)
            if i == 0 {
                renderPts[0] = point
                continue
            }
            renderCtr += 1
            renderPts[renderCtr] = point
            
            if(renderCtr == 4) {
                
                renderPts[3] = INRenderUtils.middlePoint(p1: renderPts[2], p2: renderPts[4])
                
                if(isFirstTouchPoint) {
                    ls[0] = LineSegment(p1: renderPts[0], p2: renderPts[0])
                    renderingPath.move(to: ls[0].point1)
                    isFirstTouchPoint = false
                } else {
                    ls[0] = lastSegmentOfPrev
                }
                
                let frac1 = FF/INRenderUtils.clamp(value: INRenderUtils.len_sq(p1: renderPts[0], p2: renderPts[1]), lower: LOWER, higher: UPPER)
                let frac2 = FF/INRenderUtils.clamp(value: INRenderUtils.len_sq(p1: renderPts[1], p2: renderPts[2]), lower: LOWER, higher: UPPER)
                let frac3 = FF/INRenderUtils.clamp(value: INRenderUtils.len_sq(p1: renderPts[2], p2: renderPts[3]), lower: LOWER, higher: UPPER)
                
                let ls1 = LineSegment(p1: renderPts[0], p2: renderPts[1])
                let ls2 = LineSegment(p1: renderPts[1], p2: renderPts[2])
                let ls3 = LineSegment(p1: renderPts[2], p2: renderPts[3])
                
                ls[1] = lineSegmentPerpendicular(to: ls1, length: frac1)
                ls[2] = lineSegmentPerpendicular(to: ls2, length: frac2)
                ls[3] = lineSegmentPerpendicular(to: ls3, length: frac3)
                
                renderingPath.move(to: ls[0].point1)
                renderingPath.addCurve(to: ls[3].point1, controlPoint1: ls[1].point1, controlPoint2: ls[2].point1)
                renderingPath.addLine(to: ls[3].point2)
                renderingPath.addCurve(to: ls[0].point2, controlPoint1: ls[2].point2, controlPoint2: ls[1].point2)
                renderingPath.close()
                
                lineSegments += [ls[0],ls[1],ls[2],ls[3]] // *** debug mode
                lastSegmentOfPrev = ls[3]
                renderPts[0] = renderPts[3]
                renderPts[1] = renderPts[4]
                renderCtr = 1
            }
        }
        return renderingPath
    }

    
    private func lineSegmentPerpendicular(to : LineSegment, length : CGFloat) -> LineSegment {
        let x0 = to.point1.x
        let y0 = to.point1.y
        let x1 = to.point2.x
        let y1 = to.point2.y
        
        var dx, dy : CGFloat
        dx = x1 - x0
        dy = y1 - y0
        
        var xa, ya, xb, yb : CGFloat
        xa = x1 + length/2 * dy;
        ya = y1 - length/2 * dx;
        xb = x1 - length/2 * dy;
        yb = y1 + length/2 * dx;
        
        let p1 = CGPoint(x: xa, y: ya)
        let p2 = CGPoint(x: xb, y: yb)
        
        return LineSegment(p1: p1 , p2: p2)
    }
}
