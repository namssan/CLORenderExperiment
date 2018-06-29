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
    
    fileprivate var rotateBtn = UIView()
    fileprivate var leftTopBtn = UIView()
    fileprivate var leftBottomBtn = UIView()
    fileprivate var rightTopBtn = UIView()
    fileprivate var rightBottomBtn = UIView()
    
    
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
        
        guard let sview = self.superview else { return }
        let loc = gesture.location(in: sview)
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
            let srect = sview.frame
            if srect.intersects(crect) {
                if selectType == .done {
                    let radians = atan2(contentView.transform.b, contentView.transform.a)
                    let transform = self.transform.rotated(by: radians)
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
        
        let radians = atan2(contentView.transform.b, contentView.transform.a)
        let t = CGAffineTransform.identity.rotated(by: -radians)
        var dx = at.x - startLoc.x
        var dy = at.y - startLoc.y
        let p = CGPoint(x: dx, y: dy).applying(t)

        print("dx: \(p.x) - dy:\(p.y)")
        dx = p.x
        dy = p.y
        var len = dx + dy
        var unit : CGFloat = 160.0
        if let ds = datasource {
            let zoomScale = ds.zoomScale() / 2.0
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

        var newTransform = self.originalTransform.scaledBy(x: scale, y: scale)
        if newTransform.a < 0.1 { newTransform = self.transform }
//        if newTransform.a > 5.0 { newTransform = self.transform }
        self.transform = newTransform
        resizeSelectButtons()
    }
    
    private func handleRotation(at : CGPoint) {
        let center = self.convert(selectRect, to: self.superview).center
        let dx = at.x - center.x
        let dy = at.y - center.y
        let radians = atan2(dy, dx) + (.pi / 2)
        let degrees = -radians * 180 / .pi
//        print("angle : \(degrees)")
        
        self.contentView.transform = CGAffineTransform.identity.rotated(by: radians)
    }
    
    func resizeSelectButtons() {
        
        let btns = [rotateBtn,leftTopBtn,leftBottomBtn,rightTopBtn,rightBottomBtn]
        var nscale = 1.0 / self.transform.a
        if let ds = datasource {
            let zoomScale = max(ds.zoomScale(),1.0)
            nscale /= zoomScale
        }
        nscale = min(1.0, nscale / 0.5)
        let newTransform = CGAffineTransform.identity.scaledBy(x: nscale, y: nscale)
//        print("btn scale: \(newTransform.a)")
        for btn in btns {
            btn.transform = newTransform
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
            type = selectRect.insetBy(dx: -5.0, dy: -5.0).contains(at) ? .translation : .done
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
        let anchor = CGPoint(x: totRect.center.x / self.bounds.width, y: totRect.center.y / self.bounds.height)
        self.layer.anchorPoint = anchor
        self.layer.frame = self.bounds
        self.contentView.layer.anchorPoint = anchor
        self.contentView.layer.frame = self.contentView.bounds
    }
    
    private func addSelRectLayer(rect : CGRect) {
        
        self.selectRect = rect
        removeSelRectLayer()
        if(selRectLayer == nil) {
            selRectLayer = CAShapeLayer()
            var path = UIBezierPath(rect: rect)
            selRectLayer?.path = path.cgPath
            selRectLayer?.fillColor = UIColor(hex: 0xedc533).withAlphaComponent(0.1).cgColor
            selRectLayer?.strokeColor = UIColor(hex: 0x00bf3c).cgColor
            selRectLayer?.lineWidth = 1.0
            selRectLayer?.opacity = 1.0
            selRectLayer?.lineDashPattern = [2,3]
            selRectLayer?.lineCap = kCALineCapSquare
            selRectLayer?.frame = self.bounds
            self.contentView.layer.addSublayer(selRectLayer!)
            
            for stroke in strokes {
                let layer = stroke.createLayer()
                self.contentView.layer.addSublayer(layer)
            }
            
            let size = CGSize(width: 80.0, height: 80.0)
            rotateBtn = UIView(frame: CGRect(origin: .zero, size: size))
            rotateBtn.backgroundColor = .clear
            rotateBtn.center = CGPoint(x: rect.center.x, y: rect.origin.y - 40.0)
            self.contentView.addSubview(rotateBtn)
            
            leftTopBtn = UIView(frame: CGRect(origin: .zero, size: size))
            leftTopBtn.backgroundColor = .clear
            leftTopBtn.center = rect.origin
            self.contentView.addSubview(leftTopBtn)
            
            leftBottomBtn = UIView(frame: CGRect(origin: .zero, size: size))
            leftBottomBtn.backgroundColor = .clear
            leftBottomBtn.center = CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height)
            self.contentView.addSubview(leftBottomBtn)
            
            rightTopBtn = UIView(frame: CGRect(origin: .zero, size: size))
            rightTopBtn.backgroundColor = .clear
            rightTopBtn.center = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y)
            self.contentView.addSubview(rightTopBtn)
            
            rightBottomBtn = UIView(frame: CGRect(origin: .zero, size: size))
            rightBottomBtn.backgroundColor = .clear
            rightBottomBtn.center = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
            self.contentView.addSubview(rightBottomBtn)
            
            let rknob = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 24.0, height: 24.0)))
            let img = UIImage(named: "imgRotate")
            rknob.setImage(img, for: .normal)
            rknob.backgroundColor = UIColor(hex: 0x51d579)
            rknob.layer.cornerRadius = 12.0
            rknob.layer.shadowColor = UIColor.black.cgColor
            rknob.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            rknob.layer.shadowRadius = 1
            rknob.layer.shadowOpacity = 0.8
            rknob.center = rotateBtn.center
            
            let knobSize = CGSize(width: 20.0, height: 20.0)
            let knob01 = CAShapeLayer()
            var rect = CGRect(origin: .zero, size: knobSize)
            rect.center = leftTopBtn.center
            path = UIBezierPath(roundedRect: rect, cornerRadius: knobSize.width/2.0)
            knob01.path = path.cgPath
            knob01.fillColor = UIColor(hex: 0x8ae19f).cgColor
            knob01.shadowColor = UIColor.black.cgColor
            knob01.shadowOffset = CGSize(width: 0.0, height: 0.0)
            knob01.shadowRadius = 1
            knob01.shadowOpacity = 0.8
            self.contentView.layer.addSublayer(knob01)
            
            let knob02 = CAShapeLayer()
            rect.center = leftBottomBtn.center
            path = UIBezierPath(roundedRect: rect, cornerRadius: knobSize.width/2.0)
            knob02.path = path.cgPath
            knob02.fillColor = UIColor(hex: 0x8ae19f).cgColor
            knob02.shadowColor = UIColor.black.cgColor
            knob02.shadowOffset = CGSize(width: 0.0, height: 0.0)
            knob02.shadowRadius = 1
            knob02.shadowOpacity = 0.8
            self.contentView.layer.addSublayer(knob02)
            
            let knob03 = CAShapeLayer()
            rect.center = rightTopBtn.center
            path = UIBezierPath(roundedRect: rect, cornerRadius: knobSize.width/2.0)
            knob03.path = path.cgPath
            knob03.fillColor = UIColor(hex: 0x8ae19f).cgColor
            knob03.shadowColor = UIColor.black.cgColor
            knob03.shadowOffset = CGSize(width: 0.0, height: 0.0)
            knob03.shadowRadius = 1
            knob03.shadowOpacity = 0.8
            self.contentView.layer.addSublayer(knob03)

            let knob04 = CAShapeLayer()
            rect.center = rightBottomBtn.center
            path = UIBezierPath(roundedRect: rect, cornerRadius: knobSize.width/2.0)
            knob04.path = path.cgPath
            knob04.fillColor = UIColor(hex: 0x8ae19f).cgColor
            knob04.shadowColor = UIColor.black.cgColor
            knob04.shadowOffset = CGSize(width: 0.0, height: 0.0)
            knob04.shadowRadius = 1
            knob04.shadowOpacity = 0.8
            self.contentView.layer.addSublayer(knob04)
        
            let lineLayer = CAShapeLayer()
            path = UIBezierPath()
            path.move(to: rknob.center)
            path.addLine(to: CGPoint(x: rknob.center.x, y: selectRect.origin.y - 3))
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = UIColor(hex: 0x00bf3c).cgColor
            lineLayer.lineWidth = 1.0
            lineLayer.opacity = 1.0
            lineLayer.lineDashPattern = [2,3]
            lineLayer.lineCap = kCALineCapSquare
            self.contentView.layer.addSublayer(lineLayer)
            self.contentView.addSubview(rknob)
        }
    }
    
    private func removeSelRectLayer() {
        
        if(selRectLayer != nil){
            selRectLayer?.removeFromSuperlayer()
            selRectLayer = nil
        }
    }
}
