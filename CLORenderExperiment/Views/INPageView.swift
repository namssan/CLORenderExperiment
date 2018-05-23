//
//  INPageView.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 16/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//
import UIKit
class INShapeLayer : CAShapeLayer {
    
    var tag : UInt64 = 0
    var renderType : INRenderType = .neopen
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    override init() {
        super.init()
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class INPageView: UIView {
    weak var scrollView : UIScrollView?
    
    fileprivate var dots : [INDot] = []
    fileprivate var strokes : [INStroke] = []
    fileprivate var dotViews : [UIView]  = []
    fileprivate var canvasLayer : CAShapeLayer!
    
    fileprivate var remain : Int = 0
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.backgroundColor = .white
        addCanvasLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        
        dots.removeAll()
        appendDot(loc: loc, pressure: touch.force/4.0)
        let dotView = self.addDotView(at: loc, dotColor: nil)
        self.dotViews.append(dotView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        var alltouches = [UITouch]()
        if let coalescedTouches = event?.coalescedTouches(for: touch) {
            alltouches = coalescedTouches
        }
        
        for touch in alltouches {
            let loc = touch.location(in: self)

            if let prevDot = dots.last {
                if INRenderUtils.len_sq(p1: prevDot.point, p2: loc) < 15.0 {
                    let dotView = self.addDotView(at: loc, dotColor: UIColor.gray)
                    self.dotViews.append(dotView)
//                    continue
                }
            }

            appendDot(loc: loc, pressure: touch.force/4.0)

            let dotView = self.addDotView(at: loc, dotColor: nil)
            self.dotViews.append(dotView)
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.endStroke()
 
    }
    
    private func endStroke() {
        
        let stroke = INStroke(dots: dots, rendertype: .neopen, color: UIColor.black, thickness: 4.0)
        strokes.append(stroke)
    }
    
    private func appendDot(loc : CGPoint, pressure : CGFloat) {
        print("force: \(pressure)")
        let normalizer = max(self.bounds.size.width, self.bounds.size.height)
        let dot = INDot(point: CGPoint(x: loc.x , y: loc.y), pressure: 1.0)
        dots.append(dot)
    }
    
    
    private func addCanvasLayer() {
        canvasLayer = CAShapeLayer()
        self.layer.addSublayer(canvasLayer)
    }
    
    
    func drawPath() -> String? {
        
//        self.endStroke()
        canvasLayer.removeFromSuperlayer()
        addCanvasLayer()
        let normalizer = max(self.bounds.size.width, self.bounds.size.height)
        
        for stroke in self.strokes {
            stroke.renderStroke(scale: 1.0, offset: .zero)
            let layer = stroke.createLayer()
            canvasLayer.addSublayer(layer)
        }
        
        //        self.renderFountainPen(1.0, offset: .zero)
        //        let layer = self.layer()
        //        canvasLayer.addSublayer(layer)
        //        connectDots()
        //        drawLineSegments()
        
        let str = String(format: "no strokes: %d\nremain strokes: %d", self.dots.count, remain)
        return str
    }
    
    private func addDotView(at : CGPoint, dotColor : UIColor?) -> UIView {
        var alpha : CGFloat = (dotColor == nil) ? 0.3 : 0.1
        var color = (dotColor == nil) ? UIColor.red : dotColor!
        if (dotColor == nil) && (dots.count > 1 && dots.count % 4 == 0) {
            color = UIColor.blue
        }
        let dotView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 4.0, height: 4.0)))
        dotView.layer.cornerRadius = 2.0
        dotView.backgroundColor = color
        dotView.center = at
        dotView.alpha = alpha
        self.addSubview(dotView)
        return dotView
    }
    
    func clearCanvas(removeDotView : Bool) {
        
        if removeDotView {
            for dv in dotViews {
                dv.removeFromSuperview()
            }
        }
        canvasLayer.removeFromSuperlayer()
        dots.removeAll()
        strokes.removeAll()
        dotViews.removeAll()
    }
    
    //    func connectDots() {
    //
    //        let layer = INShapeLayer()
    //        let path = UIBezierPath()
    //        for (i,dot) in dots.enumerated() {
    //            if i == 0 {
    //                path.move(to: dot)
    //                continue
    //            }
    //            path.addLine(to: dot)
    //        }
    //        layer.lineWidth = 1.0
    //        layer.fillColor = UIColor.clear.cgColor
    //        layer.strokeColor = UIColor.red.cgColor
    //        layer.path = path.cgPath
    //        canvasLayer.addSublayer(layer)
    //    }
    
    //    func drawLineSegments() {
    //
    //        for ls in self.lineSegments {
    //            let layer = INShapeLayer()
    //            let path = UIBezierPath()
    //            path.move(to: ls.point1)
    //            path.addLine(to: ls.point2)
    //            layer.lineWidth = 1.0
    //            layer.fillColor = UIColor.clear.cgColor
    //            layer.strokeColor = UIColor.green.cgColor
    //            layer.path = path.cgPath
    //            canvasLayer.addSublayer(layer)
    //        }
    //    }
    
}
