//
//  SettingStore.swift
//  CloDiary
//
//  Created by Sang Nam on 13/2/18.
//  Copyright © 2018 Sang Nam. All rights reserved.
//

import UIKit

let appDefaultColor = UIColor(hex:0x65dcff)
let kDIARY_IMAGE_FORLDER_NAME = "images"

class SettingStore: NSObject {

    static let shared = SettingStore()
    static let rndSeed = arc4random_uniform(100)
    static var renderType : INRenderType = .neopen
    
    static let localDoc : URL = {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let _localRoot = paths[0]
        return _localRoot
        
    }()
    
    class func photoDirectory(date : Date) -> URL {
    
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let str = dateFormatter.string(from: date)
        
        let url  = self.localDoc.appendingPathComponent(kDIARY_IMAGE_FORLDER_NAME).appendingPathComponent(str)
        let fm = FileManager.default
        if(!fm.fileExists(atPath: url.path)) {
            do {
                try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                
            }
        }
        return url
    }
    
    private var _selectedDate : Date?
    var selectedDate : Date {
        get {
            if(_selectedDate == nil) { return Date() }
            return _selectedDate!
        }
        set {
            _selectedDate = newValue
        }
    }
}
