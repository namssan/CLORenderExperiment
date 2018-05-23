//
//  INRenderProtocol.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

protocol INRenderProtocol: class {

    func createLayer(renderingPath : UIBezierPath) -> INShapeLayer
    func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint) -> UIBezierPath
    
}
