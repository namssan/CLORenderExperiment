//
//  INRenderer.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 24/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class INRenderer: INRenderProtocol {

    func drawLayer(at: CAShapeLayer, renderingPath : UIBezierPath?) {
        
    }
    
    func createLayer(renderingPath: UIBezierPath) -> INShapeLayer {
        let layer = INShapeLayer()
        self.drawLayer(at: layer, renderingPath: renderingPath)
        return layer
    }
    
    func renderPath(_ dots: [INDot], scale: CGFloat, offset: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        return path
    }
}
