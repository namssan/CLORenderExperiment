//
//  SliderViewController.swift
//  CLORenderExperiment
//
//  Created by Sang Nam on 17/5/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

protocol SliderViewControllerDelegate : class {
    func didUpdateSlider(type : Int, val : CGFloat)
}

class SliderViewController: UIViewController {

    @IBOutlet weak var penTypeSelector: UISegmentedControl!
    
    @IBAction func penTypeChanged(_ sender: Any) {
        SettingStore.renderType = INRenderType(rawValue: penTypeSelector.selectedSegmentIndex)!
    }
    
    
    @IBAction func slider01(_ sender: Any) {
        let slider = sender as! UISlider
        self.delegate?.didUpdateSlider(type: 0, val: CGFloat(slider.value))
    }
    
    @IBAction func slider02(_ sender: Any) {
        let slider = sender as! UISlider
        self.delegate?.didUpdateSlider(type: 1, val: CGFloat(slider.value))
    }
    
    @IBAction func slider03(_ sender: Any) {
        let slider = sender as! UISlider
        self.delegate?.didUpdateSlider(type: 2, val: CGFloat(slider.value))
    }
    
    weak var delegate : SliderViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.penTypeSelector.selectedSegmentIndex = SettingStore.renderType.rawValue
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
