//
//  INNeoPenRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INNeoPenRender: INRenderProtocol {

    private let dotNormalizer = max(A4DotCodeSize.width,A4DotCodeSize.height)
    private var x0 : CGPoint = .zero, x1 : CGPoint = .zero, x2 : CGPoint = .zero, x3 : CGPoint = .zero
    private var x0u : CGPoint = .zero, x2u : CGPoint = .zero
    private var x0n : CGPoint = .zero, x2n : CGPoint = .zero
    private var p0 : CGFloat = 0.0, p1 : CGFloat = 0.0, p2 : CGFloat = 0.0, p3 : CGFloat = 0.0

    private var start = CGPoint.zero
    private var end = CGPoint.zero
    private var ctr1 = CGPoint.zero
    private var ctr2 = CGPoint.zero
    
    private var renderingPath = UIBezierPath()
    private var dotCount = 0
    private var firstDot : INDot = INDot(point: .zero, pressure: 0.0)
    

//    private func drawDebug() -> CAShapeLayer {
//
//        let debugLayer = CAShapeLayer()
//        for dot in dots {
//
//            let dotNormalizer = max(A4DotCodeSize.width,A4DotCodeSize.height)
//            let spt = CGFloat(0.5) * (scale / dotNormalizer)
//            let len : CGFloat = spt * dot.p
//            let p = CGPoint(x: (dot.x * scale) - len/2.0, y: (dot.y * scale) - len/2.0)
//            let slayer = CAShapeLayer()
//            slayer.fillColor = UIColor.clear.cgColor
//            slayer.strokeColor = UIColor.red.cgColor
//            slayer.lineWidth = 0.1
//            slayer.opacity = 0.1
//            let rect = CGRect(origin: p, size: CGSize(width: len, height: len))
//            let path = UIBezierPath(ovalIn: rect)
//            slayer.path = path.cgPath
//            debugLayer.addSublayer(slayer)
//        }
//        return debugLayer
//    }
    
    func createLayer(color: UIColor, width: CGFloat, renderingPath: UIBezierPath) -> CAShapeLayer {
        let layer = CAShapeLayer()
        drawLayer(at: layer, color: color, width: width, renderingPath: renderingPath)
        return layer
    }
    
    func drawStroke(at ctx: CGContext, color: UIColor, width: CGFloat, renderingPath: UIBezierPath) {
    
        ctx.setStrokeColor(UIColor.clear.cgColor);
        ctx.setFillColor(color.cgColor);
        ctx.addPath(renderingPath.cgPath);
        ctx.fillPath();
    }
    
    func drawLayer(at layer: CAShapeLayer, color: UIColor, width: CGFloat, renderingPath: UIBezierPath) {
        
        layer.lineJoin = kCALineJoinRound
        layer.lineCap = kCALineCapRound
        
//        let degrees = -20.0
//        let radians = CGFloat(degrees * Double.pi / 180)
//        let t = CGAffineTransform(rotationAngle: radians)
//            ApplyCenteredPathTransform(path, t)
//            print("transform: \(t)")
        
        layer.lineWidth = 0.0
        layer.path = renderingPath.cgPath
        layer.shadowColor = UIColor.clear.cgColor
        layer.fillColor = color.cgColor
        layer.strokeColor = UIColor.clear.cgColor
        
//        let debugLayer = self.drawDebug()
//        at.addSublayer(debugLayer)
    }
    
    private func scaledPressure(_ scale : CGFloat) -> CGFloat {
        
        return min(scale, scale * 0.1 * CGFloat(dotCount))
    }
    
    private func renderStart(dot0 : INDot, dot1 : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) {
        
        renderingPath = UIBezierPath()
        let scaled_pen_thickness = width * (scale / dotNormalizer)
        
        x0 = dot0.point * scale + offset
        p0 = scaledPressure(dot0.p)
        x1 = dot1.point * scale + offset
        p1 = scaledPressure(dot1.p)
        x0u = x1.unit(to: x0)
        x0u = x0u * (scaled_pen_thickness * p0 / 2.0)
        x0n = x0u.norm()
        
        // Trip back path will be saved.
        start = x0 - x0n
        end = x0 + x0n
        ctr1 = x0 - x0n - x0u
        ctr2 = x0 + x0n - x0u
        
        renderingPath.move(to: start)
        renderingPath.addCurve(to: end, controlPoint1: ctr1, controlPoint2: ctr2)
        renderingPath.addLine(to: start)
        renderingPath.close()
    }
    
    private func renderMiddle(dot : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) {
        
        let scaled_pen_thickness = width * (scale / dotNormalizer)
        
        x3 = dot.point * scale + offset
        p3 = scaledPressure(dot.p)
        x2 = x1.middle(to: x3)
        p2 = (p1 + p3) / 2.0
        x2u = x2.unit(to: x1)
        x2u = x2u * (scaled_pen_thickness * p2 / 2.0)
        x2n = x2u.norm()
        
        let len = x2.len(to: x1) * 2.0
        if len < 0.6 {
//            print("skip this---> \(len)")
            return
        }
        
        // The + boundary of the stroke
        start = x0 + x0n
        end = x2 + x2n
        ctr1 = x1 + x0n
        ctr2 = x1 + x2n
        renderingPath.move(to: start)
        renderingPath.addCurve(to: end, controlPoint1: ctr1, controlPoint2: ctr2)
        
        end = x2 - x2n
        ctr1 = x2 + x2n - x2u
        ctr2 = x2 - x2n - x2u
        renderingPath.addCurve(to: end, controlPoint1: ctr1, controlPoint2: ctr2)
        
        // THe - boundary of the stroke
        end = x0 - x0n
        ctr1 = x1 - x2n
        ctr2 = x1 - x0n
        renderingPath.addCurve(to: end, controlPoint1: ctr1, controlPoint2: ctr2)
        renderingPath.close()
        
        x0 = x2
        p0 = p2
        x1 = x3
        p1 = p3
        x0n = x2n
    }
    
    
    func buildDot(dot : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) -> UIBezierPath {
        
        dotCount += 1
        if dotCount == 1 {
            renderingPath = UIBezierPath()
            firstDot = dot
        }
        if dotCount == 2 {
            renderStart(dot0: firstDot, dot1: dot, scale: scale, offset: offset, width: width)
        }
        if dotCount > 2 {
            renderMiddle(dot: dot, scale: scale, offset: offset, width: width)
        }
        return renderingPath
    }
    
    func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint, width: CGFloat) -> UIBezierPath {
        
        renderingPath = UIBezierPath()
        
        for (i,dot) in dots.enumerated() {
            
            if i == 0 { continue }
            if i == 1 {
                renderStart(dot0: dots[0], dot1: dots[1], scale: scale, offset: offset, width: width)
                continue
            }
//            if i == (dots.count - 1) {
//                _ = renderEnd(dot: dot, scale: scale, offset: offset, width: width)
//                continue
//            }
            renderMiddle(dot: dot, scale: scale, offset: offset, width: width)
        }
        return renderingPath
    }
    
}
