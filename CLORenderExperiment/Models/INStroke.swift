//
//  INStroke.swift
//  IdeaNotes
//
//  Created by Sang Nam on 2/07/2016.
//  Copyright © 2016 Sang Nam. All rights reserved.
//

import UIKit

enum INRenderType : Int {
    case neopen
    case foutain
    case neon
    case marker
    
    var renderer : INRenderProtocol {
        switch self {
        case .neopen: return INNeoPenRender()
        case .foutain: return INFountainRender()
        case .neon: return INNeonRender()
        default: return INDotCircleRender()
        }
    }
}


@objc class INStroke: NSObject {
    
    var xs = [Float32]()
    var ys = [Float32]()
    var ps = [Float32]()
    var ts = [UInt64]()
    
    private let internalQueue = DispatchQueue(label: "INStroke.InternalQueue")
    private var renderer : INRenderProtocol = INNeoPenRender()
    private var viewSize : CGSize = CGSize(width: 1.0, height: 1.0)
    
    var renderType : INRenderType = .neopen
    var dotCount : Int32 = 0
    var thickness : Float32 = 0.0
    var startTime : UInt64 = 0
    var color : UIColor = UIColor.black
    var isHidden : Bool = false
    var totalBound : CGRect {
        get {
            return renderingPath.bounds.insetBy(dx: -CGFloat(thickness), dy: -CGFloat(thickness))
        }
    }
    
    var renderingPath = UIBezierPath()
    
    override init() {
        super.init()
    }
    
    init(rendertype type: INRenderType, color penColor : UIColor, thickness penThickness : CGFloat) {
        
        renderType = type
        renderer = type.renderer
        dotCount = 0
        color = penColor
        thickness = Float32(penThickness)
        
        super.init()
    }
    
    init(dots penDots : [INDot], rendertype type: INRenderType, color penColor : UIColor, thickness penThickness : CGFloat) {
        
        renderType = type
        renderer = type.renderer
        dotCount = Int32(penDots.count)
        color = penColor
        thickness = Float32(penThickness)
        
        var firstStroke = true
        
        for dot in penDots {
            if(firstStroke) {
                startTime = UInt64(dot.t)
                firstStroke = false
            }
            xs.append(Float32(dot.x))
            ys.append(Float32(dot.y))
            ps.append(Float32(dot.p))
            ts.append(UInt64(dot.t))
        }
        super.init()
    }
    
    init(penStroke stroke : NPStroke, rendertype type: INRenderType, color penColor : UIColor, thickness penThickness : CGFloat) {
        
        renderType = type
        renderer = type.renderer
        dotCount = stroke.dataCount
        startTime = stroke.getStartTime()
        color = penColor
        thickness = Float32(penThickness)
        
        for i in 0...dotCount-1 {
            xs.append(Float32(stroke.getX(i)))
            ys.append(Float32(stroke.getY(i)))
            ps.append(Float32(stroke.getP(i)))
            ts.append(UInt64(stroke.getT(i)))
        }
        super.init()
    }
    
    func copyStroke() -> INStroke {
        
        var dots = [INDot]()
        if(dotCount > 0) {
            for idx in 0...dotCount-1 {
                let i = Int(idx)
                let x = CGFloat(xs[i])
                let y = CGFloat(ys[i])
                let p = CGFloat(ps[i])
                let t = TimeInterval(ts[i])
                let dot = INDot(point: CGPoint(x: x, y: y), pressure: p, time: t)
                
                dots.append(dot)
            }
        }
        let copy = INStroke(dots: dots, rendertype: renderType, color: color, thickness: CGFloat(thickness))
        copy.startTime = startTime
        copy.renderingPath = UIBezierPath(cgPath: renderingPath.cgPath)
        
        return copy
    }
    
    func createLayer() -> CAShapeLayer {
        let layer = renderer.createLayer(color: color, width: CGFloat(thickness), renderingPath: renderingPath)
        
        let bounds = renderingPath.bounds
        let anchor = CGPoint(x: bounds.midX/viewSize.width, y: bounds.midY/viewSize.height)
        
        layer.anchorPoint = anchor
        layer.frame = CGRect(origin: .zero, size: viewSize)
        let degrees = -20.0
        let radians = CGFloat(degrees * Double.pi / 180)
        //        layer.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)//CATransform3DMakeScale(1.0, 2.0, 1.0)
        //        layer.transform = CATransform3DMakeScale(1.0, 2.0, 1.0)
        //        print("bounds => \(bounds) ---> anchor: \(anchor)")
    
        return layer
    }
    
    private func renderStroke(size : CGSize, offset : CGPoint) -> UIBezierPath {
        
        self.viewSize = size
        let normalizer = max(size.width, size.height)
        
        var dots = [INDot]()
        for idx in 0..<dotCount {
            let i = Int(idx)
            let x = CGFloat(xs[i])
            let y = CGFloat(ys[i])
            let p = CGFloat(ps[i])
            let dot = INDot(point: CGPoint(x: x, y: y), pressure: p)
            dots.append(dot)
        }
        
        renderingPath = renderer.renderPath(dots, scale: normalizer, offset: offset, width: CGFloat(thickness))
        return renderingPath
    }
    
    func appendDot(dot : INDot, size : CGSize, offset : CGPoint) -> UIBezierPath {
        
        self.viewSize = size
        let normalizer = max(size.width, size.height)
        
        if dotCount == 0 {
            startTime = UInt64(dot.t)
        }
        xs.append(Float32(dot.x))
        ys.append(Float32(dot.y))
        ps.append(Float32(dot.p))
        ts.append(UInt64(dot.t))
        dotCount += 1
        
        if renderType == .neopen {
            renderingPath = renderer.buildDot!(dot: dot, scale: normalizer, offset: offset, width: CGFloat(thickness))
            return renderingPath
        }
        
        return renderStroke(size: size, offset: offset)
    }
    
    //    func appendDotEnd(size : CGSize, offset : CGPoint) -> UIBezierPath {
    //
    //        let normalizer = max(size.width, size.height)
    //
    //        if renderType == .neopen {
    //            let dot1 = getDot(at: Int(dotCount) - 2)
    //            let dot2 = getDot(at: Int(dotCount) - 1)
    //            let uv = dot1.point.unit(to: dot2.point)
    //            let len = dot1.point.len(to: dot2.point)
    //            let vec = dot2.point + (uv * len * 2.0)
    //            let p = dot2.p / 2.0
    //            let dot = INDot(point: vec, pressure: p)
    //
    //            renderingPath = renderer.renderEnd!(dot: dot2, scale: normalizer, offset: offset, width: CGFloat(thickness))
    //        }
    //        return renderingPath
    //    }
    
    func drawStroke(ctx : CGContext) {
        drawStroke(ctx: ctx, strokeColor: color)
    }
    
    private func drawStroke(ctx : CGContext, strokeColor : UIColor = UIColor.black) {
        
        ctx.saveGState()
        let color = isHidden ? strokeColor.withAlphaComponent(0.15) : strokeColor
        renderer.drawStroke(at: ctx, color: color, width: CGFloat(thickness), renderingPath: renderingPath)
        ctx.restoreGState()
        
    }
    
    
    func readStroke(_ strokeData : NSData, pos : Int) -> Int {
        
        var length : Int = 0
        var position : Int = pos
        
        var type : Int = 0
        length = MemoryLayout<UInt32>.size;
        var range : NSRange = NSRange.init(location: position, length: length)
        (strokeData as NSData).getBytes(&type, range: range)
        renderType = INRenderType(rawValue: type)!
        
        position += length
        var colorInt : UInt32 = 0
        length = MemoryLayout<UInt32>.size;
        range = NSRange.init(location: position, length: length)
        strokeData.getBytes(&colorInt, range: range)
        color = UIColor(intColor: colorInt)
        
        position += length
        length = MemoryLayout<Float32>.size;
        range = NSRange.init(location: position, length: length)
        strokeData.getBytes(&thickness, range: range)
        
        position += length
        length = MemoryLayout<UInt64>.size;
        range = NSRange.init(location: position, length: length)
        strokeData.getBytes(&startTime, range: range)
        
        position += length
        length = MemoryLayout<Int32>.size;
        range = NSRange.init(location: position, length: length)
        strokeData.getBytes(&dotCount, range: range)
        
        var xxs : Float32 = 0
        var yys : Float32 = 0
        var pps : Float32 = 0
        var tts : UInt64 = 0
        
        if(dotCount > 0) {
            for _ in 0...dotCount-1 {
                
                position += length
                length = MemoryLayout<Float32>.size;
                range = NSRange.init(location: position, length: length)
                strokeData.getBytes(&xxs, range: range)
                
                position += length
                length = MemoryLayout<Float32>.size;
                range = NSRange.init(location: position, length: length)
                strokeData.getBytes(&yys, range: range)
                
                position += length
                length = MemoryLayout<Float32>.size;
                range = NSRange.init(location: position, length: length)
                strokeData.getBytes(&pps, range: range)
                
                position += length
                length = MemoryLayout<UInt64>.size;
                range = NSRange.init(location: position, length: length)
                strokeData.getBytes(&tts, range: range)
                
                let ttts = tts + startTime
                
                xs.append(xxs)
                ys.append(yys)
                ps.append(pps)
                ts.append(ttts)
            }
        }
        
        position += length
        
        return (position - pos)
    }
    
    func writeStroke() -> Data {
        
        let strokeData = NSMutableData()
        
        var type = renderType.rawValue
        strokeData.append(&type, length: MemoryLayout<UInt32>.size)
        var colorInt = color.toInt()
        strokeData.append(&colorInt, length: MemoryLayout<UInt32>.size)
        strokeData.append(&thickness, length: MemoryLayout<Float32>.size)
        strokeData.append(&startTime, length: MemoryLayout<UInt64>.size)
        strokeData.append(&dotCount, length: MemoryLayout<Int32>.size)
        
        if(dotCount > 0) {
            for i in 0...dotCount-1 {
                let idx = Int(i)
                
                var x = xs[idx]
                var y = ys[idx]
                var p = ps[idx]
                var t = ts[idx] - startTime
                
                strokeData.append(&x, length: MemoryLayout<Float32>.size)
                strokeData.append(&y, length: MemoryLayout<Float32>.size)
                strokeData.append(&p, length: MemoryLayout<Float32>.size)
                strokeData.append(&t, length: MemoryLayout<UInt64>.size)
            }
        }
        
        return strokeData as Data
    }
    
    func firstPoint() -> CGPoint {
        let x = Double(xs[0])
        let y = Double(ys[0])
        return CGPoint(x: x, y: y)
    }
    
    func getDot(at : Int) -> INDot {
        if at < 0 || at >= dotCount {
            return INDot(point: .zero, pressure: 0.0)
        }
        let x = Double(xs[at])
        let y = Double(ys[at])
        let p = CGFloat(ps[at])
        let t = Double(ts[at])
        return INDot(point: CGPoint(x: x, y: y), pressure: p, time: t)
    }
    
    func translate(offset : CGPoint) {
        
        let dx = Float32(offset.x)
        let dy = Float32(offset.y)
        if(dotCount > 0) {
            for i in 0...dotCount-1 {
                let idx = Int(i)
                xs[idx] += dx
                ys[idx] += dy
            }
        }
    }
    
}
