//
//  INNeoPenRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INNeoPenRender: NSObject {

    
    func createLayer(renderingPath : UIBezierPath) -> INShapeLayer {
        
        let layer = INShapeLayer()
        layer.lineJoin = kCALineJoinRound
        layer.lineCap = kCALineCapRound
        layer.path = renderingPath.cgPath
//        layer.tag = startTime
//        layer.renderType = renderType
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.blue.cgColor
        layer.lineWidth = 0.1
        
        return layer
    }
    
    struct PathPointsStruct {
        var endPoint : CGPoint
        var ctlPoint1 : CGPoint
        var ctlPoint2 : CGPoint
    }
    
    func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint) -> UIBezierPath {
        
        let renderingPath = UIBezierPath()
        if(dots.count < 3) { return renderingPath }
        
        let scaled_pen_thickness : CGFloat = 8.5
        var x0, x1, x2, x3, y0, y1, y2, y3, p0, p1, p2, p3 : CGFloat
        var dx01, dy01, vx21, vy21 : CGFloat
        var norm : CGFloat
        var n_x0, n_y0, n_x2, n_y2 : CGFloat
        
        
        var temp = CGPoint.zero
        var endPoint = CGPoint.zero
        var controlPoint1 = CGPoint.zero
        var controlPoint2 = CGPoint.zero
        // the first actual point is treated as a midpoint
        x0 = dots[ 0 ].x * scale + offset.x + 0.1
        y0 = dots[ 0 ].y * scale + offset.y
        p0 = dots[ 0 ].p
        x1 = dots[ 1 ].x * scale + offset.x + 0.1
        y1 = dots[ 1 ].y * scale + offset.y
        p1 = dots[ 1 ].p
        
        dx01 = x1 - x0
        dy01 = y1 - y0
        // instead of dividing tangent/norm by two, we multiply norm by 2
        norm = sqrt(dx01 * dx01 + dy01 * dy01 + 0.0001) * 3.0
        dx01 = dx01 / norm * scaled_pen_thickness * p0
        dy01 = dy01 / norm * scaled_pen_thickness * p0
        n_x0 = dy01
        n_y0 = -dx01
        
        // Trip back path will be saved.
        var pathPointStore : [PathPointsStruct] = [PathPointsStruct]()
        temp.x = x0 + n_x0
        temp.y = y0 + n_y0
        
        renderingPath.move(to: temp)
        
        endPoint.x = temp.x
        endPoint.y = temp.y
        controlPoint1.x = x0 - n_x0 - dx01
        controlPoint1.y = y0 - n_y0 - dy01
        controlPoint2.x = x0 + n_x0 - dx01
        controlPoint2.y = y0 + n_y0 - dy01
        
        pathPointStore.append(PathPointsStruct(endPoint: endPoint, ctlPoint1: controlPoint1, ctlPoint2: controlPoint2))
        
        let cnt = dots.count
        for i in (2..<cnt-1) {
            
            x3 = dots[i].x * scale + offset.x // + 0.1f;
            y3 = dots[i].y * scale + offset.y
            p3 = dots[i].p
            
            x2 = (x1 + x3) / 2.0
            y2 = (y1 + y3) / 2.0
            p2 = (p1 + p3) / 2.0
            vx21 = x1 - x2
            vy21 = y1 - y2
            norm = sqrt(vx21 * vx21 + vy21 * vy21 + 0.0001) * 2.0
            vx21 = vx21 / norm * scaled_pen_thickness * p2
            vy21 = vy21 / norm * scaled_pen_thickness * p2
            n_x2 = -vy21
            n_y2 = vx21
            
            if (norm < 0.6) {
                continue
            }
            
            // The + boundary of the stroke
            endPoint.x = x2 + n_x2
            endPoint.y = y2 + n_y2
            controlPoint1.x = x1 + n_x0
            controlPoint1.y = y1 + n_y0
            controlPoint2.x = x1 + n_x2
            controlPoint2.y = y1 + n_y2
            renderingPath.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            
            // THe - boundary of the stroke
            endPoint.x = x0 - n_x0
            endPoint.y = y0 - n_y0
            controlPoint1.x = x1 - n_x2
            controlPoint1.y = y1 - n_y2
            controlPoint2.x = x1 - n_x0
            controlPoint2.y = y1 - n_y0
            pathPointStore.append(PathPointsStruct(endPoint: endPoint, ctlPoint1: controlPoint1, ctlPoint2: controlPoint2))
            
            x0 = x2
            y0 = y2
            p0 = p2
            x1 = x3
            y1 = y3
            p1 = p3
            dx01 = -vx21
            dy01 = -vy21
            n_x0 = n_x2
            n_y0 = n_y2
        }
        
        // the last actual point is treated as a midpoint
        x2 = CGFloat(dots[ cnt-1 ].x) * scale + offset.x // + 0.1f;
        y2 = CGFloat(dots[ cnt-1 ].y) * scale + offset.y
        p2 = CGFloat(dots[ cnt-1 ].p)
        
        vx21 = x1 - x2
        vy21 = y1 - y2
        norm = sqrt(vx21 * vx21 + vy21 * vy21 + 0.0001) * 2.0
        vx21 = vx21 / norm * scaled_pen_thickness * p2
        vy21 = vy21 / norm * scaled_pen_thickness * p2
        n_x2 = -vy21
        n_y2 = vx21
        
        endPoint.x = x2 + n_x2
        endPoint.y = y2 + n_y2
        controlPoint1.x = x1 + n_x0
        controlPoint1.y = y1 + n_y0
        controlPoint2.x = x1 + n_x2
        controlPoint2.y = y1 + n_y2
        renderingPath.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        
        endPoint.x = x2 - n_x2;
        endPoint.y = y2 - n_y2;
        controlPoint1.x = x2 + n_x2 - vx21;
        controlPoint1.y = y2 + n_y2 - vy21;
        controlPoint2.x = x2 - n_x2    - vx21;
        controlPoint2.y = y2 - n_y2 - vy21;
        renderingPath.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        
        endPoint.x = x0 - n_x0;
        endPoint.y = y0 - n_y0;
        controlPoint1.x = x1 - n_x2;
        controlPoint1.y = y1 - n_y2;
        controlPoint2.x = x1 - n_x0;
        controlPoint2.y = y1 - n_y0;
        renderingPath.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        
        // Trace back to the starting point
        //for (var index = pathPointStore.count-1; index >= 0; index -= 1) {
        for index in (0..<pathPointStore.count).reversed() {
            endPoint = pathPointStore[index].endPoint;
            controlPoint1 = pathPointStore[index].ctlPoint1;
            controlPoint2 = pathPointStore[index].ctlPoint2;
            
            renderingPath.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
        return renderingPath
    }
    
}
