//
//  INPageScrollView.swift
//  IdeaNotes
//
//  Created by Sang Nam on 5/1/17.
//  Copyright © 2017 Sang Nam. All rights reserved.
//

import UIKit

class INPageScrollView: UIScrollView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
//    weak var pageScrollVC : INPageScrollViewController?
    fileprivate var lastX : CGFloat = -1000.0
    fileprivate var lastY : CGFloat = -1000.0
    fileprivate var doubleTap : UITapGestureRecognizer?
    fileprivate var fingerDrawEnabled : Bool = false
    
    fileprivate var decideZooming : Bool = true
    fileprivate var isZoomOut : Bool = false
    fileprivate var lastZoomScale : CGFloat = 0.0
    
    lazy var contentView : UIView = {
        
        // content size is A4 default size
        let rect = CGRect(x: 0, y: 0, width: A4PaperSize.width, height: A4PaperSize.height)
        let view = UIView(frame: rect)
        view.backgroundColor = UIColor.white
        
        self.addSubview(view)
        return view
        
    } ()
    
    lazy var pageView : INPageView = {
        
        let rect = self.contentView.frame
        let view = INPageView(frame: rect)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.scrollView = self
        view.contentScaleFactor = 1.0
        self.contentView.addSubview(view)
        
        return view
    }()
    
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
    
        self.delegate = self
        self.setMinZoom()
        self.isScrollEnabled = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.delegate = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.centerContent()

    }
    
//    func enableFingerDraw(enabled : Bool) {
//        
//        fingerDrawEnabled = enabled
//        
//        if(enabled) {
//            self.panGestureRecognizer.minimumNumberOfTouches = 2
//            self.pageView.addSinglePanGesture()
//
//        } else {
//            self.panGestureRecognizer.minimumNumberOfTouches = 1
//            self.pageView.removeSinglePanGesture()
//        }
//    }

    func setMinZoom() {
        
        let contentSize = self.pageView.bounds.size
        let viewSize    = self.bounds.size
        
        let w = contentSize.width
        let h = contentSize.height
        let W = viewSize.width
        let H = viewSize.height
        
        let wRatio = w / W
        let hRatio = h / H
        let ratio = max(wRatio,hRatio)
        
        let minZoomScale = CGFloat(Float((Int(roundf(Float(1.0)/Float(ratio) * Float(100.0)) - 1)))*Float(0.01))
        
        self.contentSize = contentSize
        self.maximumZoomScale = 30.0
        self.minimumZoomScale = minZoomScale
        self.zoomScale = minimumZoomScale
    }
    
    func centerContent() {
        
        let subView = self.subviews[0]
            
        let w = contentSize.width
        let h = contentSize.height
        let W = self.bounds.size.width
        let H = self.bounds.size.height - 44.0
        
        let offX = max((W-w)*0.5,0.0)
        let offY = max((H-h)*0.5,0.0)
        
        subView.center = CGPoint(x: w * 0.5 + offX, y: h * 0.5 + offY)
//        print("center: w:\(w) h:\(h) , W:\(W) H:\(H) , offX:\(offX) offY:\(offY) ---> \(subView.center)")
    }
    
    func adjustPageView(at point : CGPoint, scale : CGFloat) {
        
        let W = self.bounds.size.width
        let H = self.bounds.size.height
        var visibleRect : CGRect = .zero
        visibleRect.origin = self.contentOffset
        visibleRect.size = self.bounds.size
        let zscale = 1.0 / self.zoomScale
        visibleRect.origin.x *= zscale
        visibleRect.origin.y *= zscale
        visibleRect.size.width *= zscale
        visibleRect.size.height *= zscale
        
        //print("visible rect  -->  \(visibleRect)")
        
        let x = point.x * scale
        let y = point.y * scale
        if((x >= visibleRect.origin.x) && (y >= visibleRect.origin.y)
            && (x <= visibleRect.origin.x+visibleRect.size.width) && (y <= visibleRect.origin.y + visibleRect.size.height)) {
            return
        }
        
        var startX = (point.x * scale * zoomScale) - W/2.0
        var startY = (point.y * scale * zoomScale) - H/2.0
        if(startX < 0.0) { startX = 0.0 }
        if(startY < 0.0) { startY = 0.0 }
        
        if(fabs(lastX - startX) > 50.0) { lastX = startX }
        if(fabs(lastY - startY) > 50.0) { lastY = startY }
        
        //      if((contentInset.top <= 0.0) && (contentInset.left <= 0.0)) {
        let rect = CGRect(x: lastX + self.frame.origin.x, y: lastY + self.frame.origin.y, width: W, height: H)
        self.scrollRectToVisible(rect, animated: true)
        //      }
    }
    
    func adjustZoomScale(at point : CGPoint) {
        
        var adjustZoomScale = self.zoomScale * 4.0
        if (adjustZoomScale > maximumZoomScale) { adjustZoomScale = maximumZoomScale }
        
        var p = point
        
        if(zoomScale >= (maximumZoomScale - 1.0)) {
            self.setZoomScale(minimumZoomScale, animated: true)
            return
        }
        
        let w = self.contentSize.width
        let h = self.contentSize.height
        let W = self.bounds.size.width
        let H = self.bounds.size.height
        
        let offX = max((W-w)*0.5, 0.0)
        let offY = max((H-h)*0.5, 0.0)
        
        p.x = p.x - offX
        p.y = p.y - offY
        
        let zoomFactor = 1.0 / zoomScale
        
        p.x = p.x * zoomFactor
        p.y = p.y * zoomFactor
        
        var rect : CGRect = .zero
        rect.size.width = self.frame.width / adjustZoomScale
        rect.size.height = self.frame.height / adjustZoomScale
        rect.origin.x = p.x - rect.size.width * 0.5
        rect.origin.y = p.y - rect.size.height * 0.5
        
        self.zoom(to: rect, animated: true)
    }
    
    
}



extension INPageScrollView : UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {

    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if(decideZooming) {
            decideZooming = false
            
            if(scrollView.zoomScale > lastZoomScale) {
//                print("-- zoom in")
                isZoomOut = false
            } else {
//                print("-- zoom out")
                isZoomOut = true
            }
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        let reached = (scale <= (minimumZoomScale + 0.001))
        if(!isZoomOut) {
            //self.pageView.invalidateTiles()
        }
        
        lastZoomScale = scrollView.zoomScale
        decideZooming = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}

