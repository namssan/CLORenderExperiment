//
//  INSelectionView.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 28/6/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

enum INSelectType: Int {
    case none
    case translation
    case rotation
    case lefttop
    case righttop
    case leftbottom
    case rightbottom
    
    var string : String  {
        switch self {
            case .translation: return "translation"
            case .rotation: return "rotation"
            case .lefttop: return "lefttop"
            case .righttop: return "righttop"
            case .leftbottom: return "leftbottom"
            case .rightbottom: return "rightbottom"
            default: return "none"
        }
    }
}

protocol INSelectionViewDelegate : class {
    func didApplyTransform(transform: CGAffineTransform)
}

class INSelectionView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var delegate : INSelectionViewDelegate?
    
    fileprivate var startLoc : CGPoint = .zero
    fileprivate var startCenter : CGPoint = .zero
    fileprivate var moveOffset : CGPoint = .zero
    
    fileprivate var selectType : INSelectType = .none
    fileprivate var selectRect : CGRect = .zero
    fileprivate var selRectLayer : CAShapeLayer?
    
    fileprivate var strokes = [INStroke]()
    fileprivate var originalTransform : CGAffineTransform = CGAffineTransform.identity
    

    convenience init(frame: CGRect, strokes : [INStroke]) {
        self.init(frame: frame)
        self.strokes = strokes
        addSelectRectLayer()
    }
    
    @objc func handlePanGesture(_ gesture : UILongPressGestureRecognizer) {
        
        let loc = gesture.location(in: self.superview)
        var loc1 = gesture.location(in: self)
        var loc2 = gesture.location(in: self)
        loc2.x /= originalTransform.a
        loc2.y /= originalTransform.a
        let state = gesture.state
        
        print("loc1 :\(loc1) --- \(loc2)")
        
        if state == .began {
            selectType = selectRect.insetBy(dx: -15.0, dy: -15.0).contains(loc1) ? .translation : .none
            if selectType == .none {
                let transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                delegate?.didApplyTransform(transform: transform)
                
            } else {
                startLoc = loc
                startCenter = self.center
                originalTransform = self.transform
                // check touch point of finger
                moveOffset = CGPoint(x: loc1.x - selectRect.origin.x, y: loc1.y - selectRect.origin.y)
                selectType = decideSelectType(at: loc1)
            }
            
        } else if(gesture.state == .ended || gesture.state == .cancelled) {
            print("selection type: \(selectType.string)")
            
        } else {
            guard selectType != .none else { return }
            
            if selectType == .translation {
                handleTranslation(at: loc)
            } else if selectType == .rotation {
                
            } else {
                handleScale(at: loc, type: selectType)
            }
        }
    }
    
    private func handleTranslation(at : CGPoint) {
        
        var loc = at
        let xMargin = min(selectRect.width * 0.3, 30.0)
        let yMargin = min(selectRect.height * 0.3, 30.0)
        let margin = min(xMargin,yMargin)
        if((loc.x - moveOffset.x) < -(selectRect.width - margin)) {
            loc.x = -(selectRect.width - margin) + moveOffset.x
        }
        if((loc.y - moveOffset.y) < -(selectRect.height - margin)) {
            loc.y = -(selectRect.height - margin) + moveOffset.y
        }
        
        if let superSize = self.superview?.frame.size {
            if((loc.x - moveOffset.x) > (superSize.width - margin)) {
                loc.x = (superSize.width - margin) + moveOffset.x
            }
            if((loc.y - moveOffset.y) > (superSize.height - margin)) {
                loc.y = (superSize.height - margin) + moveOffset.y
            }
        }
        let dx = loc.x - startLoc.x
        let dy = loc.y - startLoc.y
//        let nx = startCenter.x + dx
//        let ny = startCenter.y + dy
//        self.center = CGPoint(x: nx, y: ny)
        self.transform = self.originalTransform.translatedBy(x: dx, y: dy)
        
    }
    
    private func handleScale(at : CGPoint, type : INSelectType) {
        
        var scale : CGFloat = 1.0
        var loc = at
        let dx = loc.x - startLoc.x
        let dy = loc.y - startLoc.y

        if type == .lefttop {
            scale = 1.0 - dx / 80.0
        }
    
        let newTransform = self.originalTransform.scaledBy(x: scale, y: scale)
        if newTransform.a < 0.1  {
            print("transform scale too small: \(self.transform.a)")
            return
        }
        self.transform = newTransform
    }
    
    
    private func decideSelectType(at : CGPoint) -> INSelectType {
        
        var type : INSelectType = .translation
        
        let p = at - selectRect.origin
        if p.x < 30.0 {
            if p.y < 30 {
                type = .lefttop
            } else if p.y > (selectRect.height - 30.0) {
                type = .leftbottom
            }
        } else if p.x > (selectRect.width - 30.0) {
            if p.y < 30 {
                type = .righttop
            } else if p.y > (selectRect.height - 30.0) {
                type = .rightbottom
            }
        }
        
        return type
    }
    
    private func addSelectRectLayer() {
        
        var totRect : CGRect = .zero
        var isFirst = true
        
        for stroke in strokes {
            
            let rect = stroke.totalBound
            if isFirst {
                isFirst = false
                totRect = rect
                continue
            }
            totRect = totRect.union(rect)
        }
//        print("total rect: \(totRect)")
        addSelRectLayer(rect: totRect)
    }
    
    private func addSelRectLayer(rect : CGRect) {
        
        self.selectRect = rect
        removeSelRectLayer()
        if(selRectLayer == nil) {
            selRectLayer = CAShapeLayer()
            let path = UIBezierPath(rect: rect)
            selRectLayer?.path = path.cgPath
            selRectLayer?.fillColor = UIColor.lightGray.cgColor
            selRectLayer?.strokeColor = UIColor.gray.cgColor
            selRectLayer?.lineWidth = 0.2
            selRectLayer?.opacity = 0.3
            selRectLayer?.lineDashPattern = [1,0.8]
            selRectLayer?.lineCap = kCALineCapRound
            selRectLayer?.frame = self.bounds
            self.layer.addSublayer(selRectLayer!)
        }
    }
    
    private func removeSelRectLayer() {
        
        if(selRectLayer != nil){
            selRectLayer?.removeFromSuperlayer()
            selRectLayer = nil
        }
    }
}
