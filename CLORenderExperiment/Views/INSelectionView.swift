//
//  INSelectionView.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 28/6/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

enum INSelectType: Int {
    case done
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
            default: return "Done"
        }
    }
}

protocol INSelectionViewDelegate : class {
    func didApplyTransform(transform: CGAffineTransform)
    func didMoveOutOfView()
}

protocol INSelectionViewDataSource : class {
    func zoomScale() -> CGFloat
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
    var datasource : INSelectionViewDataSource?
    
    fileprivate var startLoc : CGPoint = .zero

    
    fileprivate var selectType : INSelectType = .done
    fileprivate var selectRect : CGRect = .zero
    fileprivate var selRectLayer : CAShapeLayer?
    
    fileprivate var strokes = [INStroke]()
    fileprivate var originalTransform : CGAffineTransform = CGAffineTransform.identity
    
    fileprivate var rotateBtn = UIButton()
    fileprivate var leftTopBtn = UIButton()
    fileprivate var leftBottomBtn = UIButton()
    fileprivate var rightTopBtn = UIButton()
    fileprivate var rightBottomBtn = UIButton()
    
    
    lazy var contentView : UIView = {
        
        let view = UIView(frame: self.bounds)
        self.addSubview(view)
        
        return view
    } ()
    

    convenience init(frame: CGRect, strokes : [INStroke]) {
        self.init(frame: frame)
        self.strokes = strokes
        addSelectRectLayer()
    }
    
    @objc func handlePanGesture(_ gesture : UILongPressGestureRecognizer) {
        
        let loc = gesture.location(in: self.superview)
        let loc1 = gesture.location(in: self.contentView)
        let state = gesture.state
        
        if state == .began {
            startLoc = loc
            selectType = decideSelectType(at: loc1)
            
            if selectType == .rotation {
                originalTransform = self.contentView.transform
            } else {
                originalTransform = self.transform
            }
            
        } else if(gesture.state == .ended || gesture.state == .cancelled) {
            print("selection type: \(selectType.string)")
            // check if selectRect is out of view
            let crect = self.convert(selectRect, to: self.superview).insetBy(dx: 10.0, dy: 10.0)
            let srect = self.superview!.frame
            if srect.intersects(crect) {
                if selectType == .done {
                    let transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    delegate?.didApplyTransform(transform: transform)
                } else {
                    // do nothing
                }
            } else {
                delegate?.didMoveOutOfView()
            }
            
        } else {
            guard selectType != .done else { return }
            
            if selectType == .translation {
                handleTranslation(at: loc)
            } else if selectType == .rotation {
                handleRotation(at: loc)
            } else {
                handleScale(at: loc, type: selectType)
            }
        }
    }
    
    private func handleTranslation(at : CGPoint) {
        
        let dx = (at.x - startLoc.x) / self.transform.a
        let dy = (at.y - startLoc.y) / self.transform.a
        self.transform = self.originalTransform.translatedBy(x: dx, y: dy)
    }
    
    private func handleScale(at : CGPoint, type : INSelectType) {
        
        var scale : CGFloat = 1.0
        let dx = at.x - startLoc.x
        let dy = at.y - startLoc.y

        var len = dx + dy
        var unit : CGFloat = 160.0
        if let ds = datasource {
            let zoomScale = ds.zoomScale() / 3.0
            if zoomScale > 1.0 { unit /= zoomScale }
        }
        
        if type == .lefttop {
            len = -dx - dy
        } else if type == .righttop {
            len = dx - dy
        } else if type == .leftbottom {
            len = -dx + dy
        }
        len /= 2.0
        if len < 0 { unit *= 1.5 }
        scale = max(1.0 + len / unit, 0.0)
    
//        print("new scale: \(scale)")
        var newTransform = self.originalTransform.scaledBy(x: scale, y: scale)
        if newTransform.a < 0.1 { newTransform = self.transform }
        if newTransform.a > 5.0 { newTransform = self.transform }

        self.transform = newTransform
        resizeSelectButtons()
    }
    
    private func handleRotation(at : CGPoint) {
        self.contentView.transform = self.originalTransform.rotated(by: 1.0)
    }
    
    func resizeSelectButtons() {
        
        let btns = [rotateBtn,leftTopBtn,leftBottomBtn,rightTopBtn,rightBottomBtn]
        var nscale = 1.0 / self.transform.a
        if let ds = datasource {
            let zoomScale = ds.zoomScale()
            nscale /= zoomScale
        }
        nscale = min(1.0, max(0.3, nscale))
        for btn in btns {
            btn.transform = CGAffineTransform.identity.scaledBy(x: nscale, y: nscale)
        }
    }
    
    private func decideSelectType(at : CGPoint) -> INSelectType {
        
        var type : INSelectType = .done

        if rotateBtn.frame.contains(at) { type = .rotation }
        if leftTopBtn.frame.contains(at) { type = .lefttop }
        if leftBottomBtn.frame.contains(at) { type = .leftbottom }
        if rightTopBtn.frame.contains(at) { type = .righttop }
        if rightBottomBtn.frame.contains(at) { type = .rightbottom }
        
        if type == .done {
            type = selectRect.insetBy(dx: -15.0, dy: -15.0).contains(at) ? .translation : .done
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
            self.contentView.layer.addSublayer(selRectLayer!)
            
            for stroke in strokes {
                let layer = stroke.createLayer()
                self.contentView.layer.addSublayer(layer)
            }
            
            let size = CGSize(width: 30.0, height: 30.0)
            rotateBtn = UIButton(frame: CGRect(origin: .zero, size: size))
            rotateBtn.backgroundColor = .red
            rotateBtn.center = CGPoint(x: rect.center.x, y: rect.origin.y - 50.0)
            self.contentView.addSubview(rotateBtn)
            
            leftTopBtn = UIButton(frame: CGRect(origin: .zero, size: size))
            leftTopBtn.backgroundColor = .blue
            leftTopBtn.center = rect.origin
            self.contentView.addSubview(leftTopBtn)
            
            leftBottomBtn = UIButton(frame: CGRect(origin: .zero, size: size))
            leftBottomBtn.backgroundColor = .blue
            leftBottomBtn.center = CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height)
            self.contentView.addSubview(leftBottomBtn)
            
            rightTopBtn = UIButton(frame: CGRect(origin: .zero, size: size))
            rightTopBtn.backgroundColor = .blue
            rightTopBtn.center = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y)
            self.contentView.addSubview(rightTopBtn)
            
            rightBottomBtn = UIButton(frame: CGRect(origin: .zero, size: size))
            rightBottomBtn.backgroundColor = .blue
            rightBottomBtn.center = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
            self.contentView.addSubview(rightBottomBtn)
        }
    }
    
    private func removeSelRectLayer() {
        
        if(selRectLayer != nil){
            selRectLayer?.removeFromSuperlayer()
            selRectLayer = nil
        }
    }
}
