//
//  INRenderProtocol.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 23/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

@objc protocol INRenderProtocol {

    func createLayer(color: UIColor, width: CGFloat, renderingPath: UIBezierPath) -> CAShapeLayer
    func drawLayer(at layer: CAShapeLayer, color: UIColor, width: CGFloat, renderingPath: UIBezierPath)
    func drawStroke(at ctx: CGContext, color: UIColor, width: CGFloat, renderingPath: UIBezierPath)
    func renderPath(_ dots : [INDot], scale : CGFloat, offset : CGPoint, width : CGFloat) -> UIBezierPath
    
//    @objc optional func renderStart(dot0 : INDot, dot1 : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) -> UIBezierPath
//    @objc optional func renderMiddle(dot : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) -> UIBezierPath
//    @objc optional func renderEnd(dot : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) -> UIBezierPath
    @objc optional func buildDot(dot : INDot, scale : CGFloat, offset : CGPoint, width : CGFloat) -> UIBezierPath
}
