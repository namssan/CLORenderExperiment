//
//  ViewController.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 10/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    fileprivate var penDown = false
    fileprivate var startDot = false
    
    lazy var canvasScrollView : INPageScrollView = {
        
        let view = INPageScrollView(frame: self.view.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        
        let lConst = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
        let rConst = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        let tConst = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
        let bConst = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([lConst,rConst,tConst,bConst])
        
        self.view.bringSubview(toFront: self.infoLbl)
        return view
        
    } ()
    
    @IBOutlet weak var infoLbl: UILabel!
    
    @IBAction func neoPenBtnPressed(_ sender: Any) {
        self.showPenRegisterVC()
    }
    
    
    @IBAction func showSliderVC(_ sender: Any) {
//        self.showSliderVC()
        if self.canvasScrollView.pageView.selectionView != nil {
            self.canvasScrollView.pageView.removeSelectionView()
        } else {
            self.canvasScrollView.pageView.addSelectionVeiw()
        }
    }
    
    @IBAction func earserBtnPressed(_ sender: Any) {

        self.canvasScrollView.pageView.clearCanvas(removeDotView: true)
    }
    
    @IBAction func pathBtnPressed(_ sender: Any) {
        
//        if let str = self.canvasScrollView.pageView.drawPath() {
//            self.infoLbl.text = str
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NPCommManager.sharedInstance().dotHandler = self
        NPCommManager.sharedInstance().setPressureFilter(NPPressureFilter.bezier)
//        NPCommManager.sharedInstance().setPressureFilterBezier(CGPoint(x: 0.0, y: 0.9), ctr1: CGPoint(x: 0.5, y: 1.0), ctr2: CGPoint(x: 1.0, y: 0.1))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _ = self.canvasScrollView
    }

    func showSliderVC() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "SliderVC") as! SliderViewController
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 350, height: 350)
        vc.popoverPresentationController?.delegate = self
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
        
        let w = self.view.bounds.size.width
        let rect = CGRect(x: w - 20.0 , y: 80.0 , width: 20, height: 20)
        
        if let popover = vc.popoverPresentationController {
            popover.permittedArrowDirections = [.up]
            popover.sourceView = self.view
            popover.sourceRect = rect
        }
    }
    
    func showPenRegisterVC() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "PenRegisterVC") as! PTPenRegisterViewController
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 270, height: 310)
        vc.popoverPresentationController?.delegate = self
        self.present(vc, animated: true, completion: nil)
        
        let W = self.view.frame.width
        let rect = CGRect(x: W - 120.0, y:0, width: 0, height: 0)
        
        if let popover = vc.popoverPresentationController {
            popover.permittedArrowDirections = [.left , .right]
            popover.sourceView = self.view
            popover.sourceRect = rect
        }
    }
}

extension ViewController : SliderViewControllerDelegate {
    
    func didUpdateSlider(type: Int, val: CGFloat) {

//        self.canvasScrollView.pageView.updateValues(ff: (type == 0) ? val : nil , lw: (type == 1) ? val : nil, up: (type == 2) ? val : nil)
//        self.canvasScrollView.pageView.drawPath()
    }
}

extension ViewController : UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return adaptivePresentationStyle(for: controller)
    }
}

extension ViewController : NPDotHandler {
    
    func processDot(_ dotDic: [AnyHashable : Any]!) {
        
        guard let cmd = dotDic["type"] else { return }
        guard let pageId = dotDic["page_id"] as? Int else { return }
        let type = cmd as! String
        
        let offset : CGPoint = .zero
        let dotNormalizer : CGFloat = max(A4DotCodeSize.width,A4DotCodeSize.height)
        
        if(type.compare("stroke") == .orderedSame) {
            
            guard penDown else { return }
            guard let n = dotDic["dot"] else { return }
            
            let node = n as! NPDot
            let nx = (CGFloat(node.x) + offset.x) / dotNormalizer
            let ny = (CGFloat(node.y) + offset.y) / dotNormalizer
            let point = CGPoint(x: nx, y: ny)
            _ = INDot(point:point , pressure: CGFloat(node.pressure))
            //            print("point: \(point) - pressure: \(node.pressure)")
            if(startDot) {
                startDot = false
                self.canvasScrollView.pageView.drawBegan(at: point, pressure: CGFloat(node.pressure))
            } else {
                self.canvasScrollView.pageView.drawMoved(at: point, pressure: CGFloat(node.pressure))
            }
            
            
        } else if(type.compare("updown") == .orderedSame) {
            
            guard let s = dotDic["status"] else { return }
            let status = s as! String
            
            if(status.compare("down") == .orderedSame) {
                
                penDown = true
                startDot = true
                
            } else {
                penDown = false
                self.canvasScrollView.pageView.drawEnded()
            }
            
        } else {
            fatalError("impossible dictionary key")
        }
        
    }
}


extension UIViewController {
    
    var topbarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}
