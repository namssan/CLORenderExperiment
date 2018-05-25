//
//  INDot.swift
//  IdeaNotes
//
//  Created by Sang Nam on 5/1/17.
//  Copyright © 2017 Sang Nam. All rights reserved.
//


import UIKit



class Simplify {
    
    /**
     Returns an array of simplified points
     
     - parameter points:      An array of points of (maybe CGPoint or CLLocationCoordinate2D points)
     - parameter tolerance:   Affects the amount of simplification (in the same metric as the point coordinates)
     - parameter highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower.
     
     - returns: Returns an array of simplified points
     */
    class func simplify(_ points: [INDot], tolerance: Float?, highQuality: Bool = false) -> [INDot] {
        if points.count == 2 {
            return points
        }
        // both algorithms combined for awesome performance
        let sqTolerance = (tolerance != nil ? tolerance! * tolerance! : 1.0)
        var result: [INDot] = (highQuality == true ? points : simplifyRadialDistance(points, tolerance: sqTolerance))
        result = simplifyDouglasPeucker(result, tolerance: sqTolerance)
        return result
    }
    
    fileprivate class func equalsPoints(_ pointA: INDot, pointB: INDot) -> Bool {

        return (pointA.x == pointB.x && pointA.y == pointB.y)
        
    }
    
    fileprivate class func simplifyRadialDistance(_ points: [INDot], tolerance: Float!) -> [INDot] {
        guard points.count > 2 else { return points }
        var prevPoint: INDot = points.first!
        var newPoints: [INDot] = [prevPoint]
        var point: INDot = points[1]
        
        for idx in 1 ..< points.count {
            point = points[idx]
            let distance = getSqDist(point, pointB: prevPoint)
            if distance > tolerance! {
                newPoints.append(point)
                prevPoint = point
            }
        }
        
        if equalsPoints(prevPoint, pointB: point) == false {
            newPoints.append(point)
        }
        
        
        
        return newPoints
    }
    
    fileprivate class func simplifyDouglasPeucker(_ points: [INDot], tolerance: Float!) -> [INDot] {
        // simplification using Ramer-Douglas-Peucker algorithm
        let last: Int = points.count - 1
        var simplified: [INDot] = [points.first!]
        simplifyDPStep(points, first: 0, last: last, tolerance: tolerance, simplified: &simplified)
        simplified.append(points[last])
        return simplified
    }
    
    fileprivate class func simplifyDPStep(_ points: [INDot], first: Int, last: Int, tolerance: Float, simplified: inout [INDot]) {
        var maxSqDistance = tolerance
        var index = 0
        
        if last > 0 {
        for i in first + 1 ..< last {
            let sqDist = getSQSegDist(point: points[i], point1: points[first], point2: points[last])
            if sqDist > maxSqDistance {
                index = i
                maxSqDistance = sqDist
            }
        }
        }
        
        if maxSqDistance > tolerance {
            if index - first > 1 {
                simplifyDPStep(points, first: first, last: index, tolerance: tolerance, simplified: &simplified)
            }
            simplified.append(points[index])
            if last - index > 1 {
                simplifyDPStep(points, first: index, last: last, tolerance: tolerance, simplified: &simplified)
            }
        }
    }
    
    fileprivate class func getSQSegDist(point p: INDot, point1 p1: INDot, point2 p2: INDot) -> Float {
        // square distance from a point to a segment
        let point: CGPoint = p.point
        let point1: CGPoint = p1.point
        let point2: CGPoint = p2.point
        
        var x = point1.x
        var y = point1.y
        var dx = point2.x - x
        var dy = point2.y - y
        
        if dx != 0 || dy != 0 {
            let t = ( (point.x - x) * dx + (point.y - y) * dy ) / ( (dx * dx) + (dy * dy) )
            if t > 1 {
                x = point2.x
                y = point2.y
            } else if t > 0 {
                x += dx * t
                y += dy * t
            }
        }
        
        dx = point.x - x
        dy = point.y - y
        
        return Float( (dx * dx) + (dy * dy) )
    }
    
    fileprivate class func getSqDist(_ pointA: INDot, pointB: INDot) -> Float {
        // square distance between 2 points
        let dx = pointA.x - pointB.x
        let dy = pointA.y - pointB.y
        return Float( (dx * dx) + (dy * dy) )
    
    }
    
}
