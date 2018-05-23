//
//  Utils.swift
//  IdeaNotes
//
//  Created by Sang Nam on 21/08/2016.
//  Copyright © 2016 Sang Nam. All rights reserved.
//

import UIKit

class Utils : NSObject {
    
}

extension UIColor {
    
    static func appleBlue() -> UIColor {
        return UIColor(red: 14.0/255.0, green: 122.0/255.0, blue: 254.0/255.0, alpha: 1.0)
    }
    
    convenience init(intColor : UInt32) {
        
        let mask = 0x000000FF
        let a = Int(intColor >> 24) & mask
        let r = Int(intColor >> 16) & mask
        let g = Int(intColor >> 8) & mask
        let b = Int(intColor) & mask
        
        let alpha = CGFloat(a) / 255.0
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:alpha)
        
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex:Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
    
    convenience init(hexString : String) {
        let hexString  = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner    = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
//        let a = Int(color >> 24) & mask
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
//        let alpha = CGFloat(a) / 255.0
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1.0)
    }
    
    class func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return self.init(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
    
    
    func toInt() -> UInt32 {

        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(a*255)<<24 | (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return UInt32(rgb)
    }

}


