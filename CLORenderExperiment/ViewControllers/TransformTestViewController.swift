//
//  TransformTestViewController.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 25/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

class TransformTestViewController: UIViewController {

    var myLayer = CATextLayer()
    @IBOutlet weak var myView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // setup the sublayer
        addSubLayer()
        
        // do the transform
        transformExample()
    }
    
    
    func addSubLayer() {
        myLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        myLayer.backgroundColor = UIColor.blue.cgColor
        myLayer.string = "Hello"
        myView.layer.addSublayer(myLayer)
    }


    func transformExample() {
        
        // add transform code here ...
        let degrees = 30.0
        let radians = CGFloat(degrees * Double.pi / 180)
        myLayer.anchorPoint = CGPoint(x: 1.0, y: 1.0)
//        myLayer.position = CGPoint(x: 100, y: 40)
        myLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        myLayer.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
