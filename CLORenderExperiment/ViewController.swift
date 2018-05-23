//
//  ViewController.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 10/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
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
    
    @IBAction func showSliderVC(_ sender: Any) {
        self.showSliderVC()
    }
    
    @IBAction func earserBtnPressed(_ sender: Any) {

        self.canvasScrollView.pageView.clearCanvas(removeDotView: true)
    }
    
    @IBAction func pathBtnPressed(_ sender: Any) {
        
        if let str = self.canvasScrollView.pageView.drawPath() {
            self.infoLbl.text = str
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        vc.preferredContentSize = CGSize(width: 250, height: 310)
        vc.popoverPresentationController?.delegate = self
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
        
        let w = self.view.bounds.size.width
        let rect = CGRect(x: w - 20.0 , y: 80.0 , width: 20, height: 20)
        
        if let popover = vc.popoverPresentationController {
            popover.permittedArrowDirections = [.up , .right]
            popover.sourceView = self.view
            popover.sourceRect = rect
        }
    }
}

extension ViewController : SliderViewControllerDelegate {
    
    func didUpdateSlider(type: Int, val: CGFloat) {

//        self.canvasScrollView.pageView.updateValues(ff: (type == 0) ? val : nil , lw: (type == 1) ? val : nil, up: (type == 2) ? val : nil)
        self.canvasScrollView.pageView.drawPath()
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


extension UIViewController {
    
    var topbarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}
