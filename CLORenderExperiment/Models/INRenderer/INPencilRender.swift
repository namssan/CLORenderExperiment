//
//  INPencilRender.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit


class INPencilRender: NSObject {
    
    let π = CGFloat(M_PI)

    private func lineWidthForShading(context: CGContext?, touch: UITouch) -> CGFloat {
        
        // 1
        let previousLocation = touch.previousLocation(in: self)
        let location = touch.location(in: self)
        
        // 2 - vector1 is the pencil direction
        let vector1 = touch.azimuthUnitVector(in: self)
        
        // 3 - vector2 is the stroke direction
        let vector2 = CGPoint(x: location.x - previousLocation.x,
                              y: location.y - previousLocation.y)
        
        // 4 - Angle difference between the two vectors
        var angle = abs(atan2(vector2.y, vector2.x)
            - atan2(vector1.dy, vector1.dx))
        
        // 5
        if angle > π {
            angle = 2 * π - angle
        }
        if angle > π / 2 {
            angle = π - angle
        }
        
        // 6
        let minAngle:CGFloat = 0
        let maxAngle:CGFloat = π / 2
        let normalizedAngle = (angle - minAngle) / (maxAngle - minAngle)
        
        // 7
        let maxLineWidth:CGFloat = 60
        var lineWidth:CGFloat
        lineWidth = maxLineWidth * normalizedAngle
        
        // 1 - modify lineWidth by altitude (tilt of the Pencil)
        // 0.25 radians means widest stroke and TiltThreshold is where shading narrows to line.
        
        let minAltitudeAngle:CGFloat = 0.25
        let maxAltitudeAngle:CGFloat = TiltThreshold
        
        // 2
        let altitudeAngle = touch.altitudeAngle < minAltitudeAngle
            ? minAltitudeAngle : touch.altitudeAngle
        
        // 3 - normalize between 0 and 1
        let normalizedAltitude = 1 - ((altitudeAngle - minAltitudeAngle)
            / (maxAltitudeAngle - minAltitudeAngle))
        // 4
        lineWidth = lineWidth * normalizedAltitude + MinLineWidth
        
        // Set alpha of shading using force
        let minForce:CGFloat = 0.0
        let maxForce:CGFloat = 5
        
        // Normalize between 0 and 1
        let normalizedAlpha = (touch.force - minForce) / (maxForce - minForce)
        
        context!.setAlpha(normalizedAlpha)
        
        return lineWidth
    }
    
    
    private func lineWidthForDrawing(context: CGContext?, touch: UITouch) -> CGFloat {
        
        var lineWidth:CGFloat
        lineWidth = DefaultLineWidth
        
        if touch.force > 0 {  // If finger, touch.force = 0
            lineWidth = touch.force * ForceSensitivity
        }
        return lineWidth
    }
}
