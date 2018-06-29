//
//  INPageView.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 16/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//
import UIKit
import AudioToolbox

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

class INPageTiledLayer : CATiledLayer {
    
    let kLEVELS_OF_DETAIL = 16
    let kTILE_SIZE : CGFloat = (1024)
    
    override class func fadeDuration() -> CFTimeInterval {
        return 0.2
    }
    
    override init() {
        
        super.init()
        self.levelsOfDetail = kLEVELS_OF_DETAIL
        self.levelsOfDetailBias = (kLEVELS_OF_DETAIL - 1)
        
        let mainScreen = UIScreen.main
        let screenScale = mainScreen.scale
        let screenBounds = mainScreen.bounds
        let wPixel = screenBounds.size.width * screenScale
        let hPixel = screenBounds.size.height * screenScale
        //        let maxPixel = max(wPixel,hPixel)
        let sizeOfTiles = kTILE_SIZE //(maxPixel < kTILE_SIZE) ? (kTILE_SIZE / 2.0) : kTILE_SIZE
        self.tileSize = CGSize(width: sizeOfTiles, height: sizeOfTiles)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        
        super.init(layer: layer)
    }
}

class INPageView: UIView {
    weak var scrollView : INPageScrollView?
    
    fileprivate var stroke : INStroke = INStroke()
    fileprivate var strokes : [INStroke] = []
    fileprivate var canvasLayer : CAShapeLayer?
    fileprivate var guideLayer : CAShapeLayer?
    fileprivate var rederingPath : UIBezierPath = UIBezierPath()
    fileprivate var pageTransform: CGAffineTransform = CGAffineTransform.identity
    
    fileprivate var remain : Int = 0
    var selectionView : INSelectionView?
    
    override class var layerClass: AnyClass {
        return INPageTiledLayer.self
    }
    
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.backgroundColor = .white
        addGuideLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        
        //        guard isDocumentOpened else { return }
        let tileBounds = ctx.boundingBoxOfClipPath
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(tileBounds)
        
        for stroke in self.strokes {
            let bounds = stroke.totalBound
//            if(stroke.isHidden) { continue }
            if(tileBounds.intersects(bounds)) {
                stroke.drawStroke(ctx: ctx)
            }
        }
        //        ctx.setStrokeColor(self.rndColor.withAlphaComponent(0.8).cgColor)
        //        ctx.stroke(tileBounds)
    }
    
    
    func drawBegan(at : CGPoint, pressure: CGFloat) {
        let render = SettingStore.renderType
        guideLayer?.removeFromSuperlayer()
        addGuideLayer()
        
        stroke = INStroke(rendertype: render, color: SettingStore.strokeColor, thickness: 4.0)
        render.renderer.drawLayer(at: guideLayer!, color: SettingStore.strokeColor, width: 4.0, renderingPath: rederingPath)
        
        let dot = INDot(point: CGPoint(x: at.x, y: at.y), pressure: pressure)
        rederingPath = stroke.appendDot(dot: dot, size: self.bounds.size, offset: .zero)
    }
    
    func drawMoved(at : CGPoint, pressure: CGFloat) {
        let dot = INDot(point: CGPoint(x: at.x, y: at.y), pressure: pressure)
        rederingPath = stroke.appendDot(dot: dot, size: self.bounds.size, offset: .zero)
        guideLayer?.path = rederingPath.cgPath
    }
    
    func drawEnded() {
        guideLayer?.path = UIBezierPath().cgPath
        canvasLayer?.removeFromSuperlayer()
        canvasLayer = stroke.createLayer()
        
        guard stroke.dotCount >= 3 else { return }
        self.layer.insertSublayer(canvasLayer!, below: guideLayer)
        addStrokes(strokes: [stroke])
        drawDots()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard selectionView == nil else { return }
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        
        let normalizer = max(self.bounds.size.width,self.bounds.size.height)
        self.drawBegan(at: CGPoint(x: loc.x / normalizer, y: loc.y / normalizer), pressure: touch.force/4.0)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard selectionView == nil else { return }
        guard let touch = touches.first else { return }
        
        var alltouches = [touch]
        let coaledEnalbled = (SettingStore.renderType != .foutain)
        if coaledEnalbled,  let coalescedTouches = event?.coalescedTouches(for: touch) {
            alltouches = coalescedTouches
        }
        let normalizer = max(self.bounds.size.width,self.bounds.size.height)
        for touch in alltouches {
            let loc = touch.location(in: self)
            self.drawMoved(at: CGPoint(x: loc.x / normalizer, y: loc.y / normalizer), pressure: touch.force/4.0)
        }
        let loc = touch.location(in: self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard selectionView == nil else { return }
        guideLayer?.path = UIBezierPath().cgPath
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard selectionView == nil else { return }
        self.drawEnded()
    }
    
    func addGuideLayer() {
        guideLayer = CAShapeLayer()
        guideLayer!.lineJoin = kCALineJoinRound
        guideLayer!.lineCap = kCALineCapRound
        guideLayer!.fillColor = UIColor.clear.cgColor
        guideLayer!.strokeColor = SettingStore.strokeColor.cgColor
        guideLayer!.lineWidth = 3.0
        guideLayer!.drawsAsynchronously = true
        self.layer.addSublayer(guideLayer!)
    }
    
    
    func addSelectionVeiw() {
        guard strokes.count > 0 else { return }
        
        var isFirst = true
        var trect = CGRect.zero
        
        for stroke in strokes {
            stroke.isHidden = true
            if isFirst {
                isFirst = false
                trect = stroke.totalBound
                continue
            }
            trect = trect.union(stroke.totalBound)
        }
        guideLayer?.removeFromSuperlayer()
        canvasLayer?.removeFromSuperlayer()
        self.layer.setNeedsDisplay(trect)
        
        selectionView = INSelectionView(frame: self.bounds, strokes: strokes)
        selectionView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        selectionView?.delegate = self
        selectionView?.datasource = self
        self.addSubview(selectionView!)
        scrollView?.addSelectionPanGesture()
    }
    
    func removeSelectionView() {
        selectionView?.removeFromSuperview()
        selectionView = nil
        
        scrollView?.removeSelectionPanGesture()
    }
    
//    func drawPath() -> String? {
//
//        canvasLayer.removeFromSuperlayer()
//        addCanvasLayer()
//
//        for stroke in self.strokes {
//            stroke.renderStroke(size: self.bounds.size, offset: .zero)
//            let layer = stroke.createLayer()
//            canvasLayer.addSublayer(layer)
//        }
//
//        let str = String(format: "no strokes: %d\nremain strokes: %d", self.dots.count, remain)
//        return str
//    }
    
    private func addStrokes(strokes : [INStroke]) {
        
        guard strokes.count > 0 else { return }
        //        document?.undoManager.registerUndo(withTarget: self, selector: #selector(removeStrokes(strokes:)), object: strokes)
        //        document?.undoManager.setActionName("action.undo.add")
        //        document?.insertStrokes(strokes)
        
        var isFirst = true
        var trect = CGRect.zero
        
        for stroke in strokes {
            let copyStroke = stroke.copyStroke()
            //            _ = copyStroke.renderStroke(size: self.bounds.size, offset: .zero)
            let rect = copyStroke.totalBound
            if(isFirst) {
                isFirst = false
                trect = rect
            } else {
                trect = trect.union(rect)
            }
            //            self.drawBitmap(stroke: copyStroke)
            self.strokes.append(copyStroke)
        }
        
        self.layer.setNeedsDisplay(trect)
        
        //        self.delegate?.updateRedo(canRedo: document?.undoManager.canRedo)
        //        self.delegate?.updateUndo(canUndo: document?.undoManager.canUndo)
    }
    
//    private func addDotView(at : CGPoint, dotColor : UIColor?) -> UIView {
//        var alpha : CGFloat = (dotColor == nil) ? 0.3 : 0.1
//        var color = (dotColor == nil) ? UIColor.red : dotColor!
//        if (dotColor == nil) && (dots.count > 1 && dots.count % 4 == 0) {
//            color = UIColor.blue
//        }
//        let dotView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 4.0, height: 4.0)))
//        dotView.layer.cornerRadius = 2.0
//        dotView.backgroundColor = color
//        dotView.center = at
//        dotView.alpha = alpha
////        self.addSubview(dotView)
//        return dotView
//    }
    
    func drawDots() {
        
//        let normalizer = max(self.bounds.size.width,self.bounds.size.height)
//        let dots = stroke.getDots(normalizer: normalizer)
//        for dot in dots {
//            let len : CGFloat = 0.1
//            let dl = CAShapeLayer()
//            let path = UIBezierPath(roundedRect: CGRect(origin: dot.point, size: CGSize(width: len, height: len)), cornerRadius: len/2.0)
//            dl.fillColor = UIColor.black.cgColor
//            dl.path = path.cgPath
//            canvasLayer?.addSublayer(dl)
//        }
    }
    
    func clearCanvas(removeDotView : Bool) {
        
        scrollView?.removeSelectionPanGesture()
        removeSelectionView()
        selectionView = nil
        
        guideLayer?.removeFromSuperlayer()
        canvasLayer?.removeFromSuperlayer()
        pageTransform = CGAffineTransform.identity
        self.strokes.removeAll()
        self.layer.contents = nil
//        self.setNeedsDisplay()
    }
        
}

extension INPageView : INSelectionViewDelegate {
    func didApplyTransform(transform: CGAffineTransform) {

        scrollView?.removeSelectionPanGesture()
        selectionView?.removeFromSuperview()
        selectionView = nil
        print("Apply Done")
        
        pageTransform = transform
        var isFirst = true
        var trect1 = CGRect.zero
        var trect2 = CGRect.zero
        
        for stroke in strokes {
            let rect = stroke.totalBound
            if isFirst {
                isFirst = false
                trect1 = rect
                continue
            }
            trect1 = trect1.union(rect)
        }
        
        for stroke in strokes {
            stroke.isHidden = false
            ApplyCenteredPathTransformCenter(trect1.center,stroke.renderingPath, transform)
            let rect = stroke.totalBound
            if isFirst {
                isFirst = false
                trect2 = rect
                continue
            }
            trect2 = trect2.union(rect)
        }
        
        guideLayer?.removeFromSuperlayer()
        canvasLayer?.removeFromSuperlayer()
        
//        self.layer.setNeedsDisplay(trect1)
//        self.layer.setNeedsDisplay(trect2)
        self.layer.contents = nil
        self.setNeedsDisplay()
    }
    
    func didMoveOutOfView() {
        print("Out of View!!!!!!")
        clearCanvas(removeDotView: true)
        
        AudioServicesPlaySystemSound(1001)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

extension INPageView : INSelectionViewDataSource {
    func zoomScale() -> CGFloat {
        return scrollView!.zoomScale
    }
}


