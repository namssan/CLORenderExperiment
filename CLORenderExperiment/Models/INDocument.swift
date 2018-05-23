//
//  INDocument.swift
//  IdeaNotes
//
//  Created by Sang Nam on 28/06/2016.
//  Copyright © 2016 Sang Nam. All rights reserved.
//

import UIKit

let kDOCUMENT_EXTENSION:String   =     "idea"
let kMETADATA_FILENAME:String    =     "meta.data"
let kPAGEDATA_FILENAME:String    =     "page.data"


enum INDocumentError: Error {
    case ThumbnailLoadFailed
    case NoPageData
    case NoPageMeta
    case PlistReadFailed
    case SignedOutOfiCloud
}


@objc class INDocument: UIDocument {
    
    lazy var pageData : INPage = {
        var page = INPage(strokes: [INStroke]())
        if let pl = self.plist {
            if let pdata = pl[kPAGEDATA_FILENAME] {
                if let pdecode = self.decodeObject(pdata, isMeta: false) {
                    page = pdecode as! INPage
                    if(page.timeDisordered) {
                        self.updateChangeCount(.done) // try to save as soon as possible
                    }
                }
            }
        }
        return page
    }()
    
    lazy var pageMeta : INPageMeta = {
        var meta = INPageMeta()
        if let pl = self.plist {
            if let mdata = pl[kMETADATA_FILENAME] {
                if let mdecode = self.decodeObject(mdata, isMeta: true) {
                    meta = mdecode as! INPageMeta
                }
            }
        }
        return meta
    }()

    private var plist : [String: Data]?
    
    
    // writing
    override func contents(forType typeName: String) throws -> Any {

        //print("document writing....")
        
        let pageUUID = fileURL.deletingPathExtension().lastPathComponent
        let thumbnail = self.pageData.createThumbnail(pageUUID: pageUUID)
        self.pageMeta.thumbnail = thumbnail
        
        let pageData = encodeObject(self.pageData, isMeta: false)
        let metaData = encodeObject(self.pageMeta, isMeta: true)
        
        let plist: [String: Data] = [
            kMETADATA_FILENAME: metaData,
            kPAGEDATA_FILENAME: pageData
        ]

        return try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
    }
    
    
    // reading
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        guard let data = contents as? Data else {
            fatalError("Cannot handle contents of type.")
        }
        
        // Our document format is a simple plist.
        guard let pl = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String: Data] else {
            throw INDocumentError.PlistReadFailed
        }
        self.plist = pl
        
        guard let _ = pl[kPAGEDATA_FILENAME] else {
            throw INDocumentError.NoPageMeta
        }
        guard let mdata = pl[kMETADATA_FILENAME] else {
            throw INDocumentError.NoPageMeta
        }
    }
    
    
    func encodeObject(_ object : NSCoding, isMeta : Bool) -> Data {
        
        let data = NSMutableData()
        if(isMeta) {
            NSKeyedArchiver.setClassName("IdeaNotes.INPageMeta", for: INPageMeta.self)
        } else {
            NSKeyedArchiver.setClassName("IdeaNotes.INPage", for: INPage.self)
        }
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(object, forKey: "data")
        archiver.finishEncoding()
        
        return data as Data
    }
    
    func decodeObject(_ object : Data, isMeta : Bool) -> Any? {
        //        Swift.print("size: \(object.count)")
        if(isMeta) {
            NSKeyedUnarchiver.setClass(INPageMeta.self, forClassName: "IdeaNotes.INPageMeta")
        } else {
            NSKeyedUnarchiver.setClass(INPage.self, forClassName: "IdeaNotes.INPage")
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: object)
        let decode = unarchiver.decodeObject(forKey: "data")
        return decode
    }

    
//    func addStroke(_ stroke : INStroke) {
//        self.updateChangeCount(.done)
//        self.pageData.addStroke(stroke)
//    }
    
    func removeStroke(_ stroke : INStroke) {
        self.updateChangeCount(.done)
        self.pageData.removeStroke(stroke)
    }
    
    func removeStroke(at index: Int) {
        self.updateChangeCount(.done)
        self.pageData.removeStroke(at: index)
    }
    
    func insertStroke(_ stroke : INStroke) {
        self.updateChangeCount(.done)
        self.pageData.insertStroke(stroke)
    }
    
    func insertStrokes(_ strokes : [INStroke]) {
        self.updateChangeCount(.done)
        for stroke in strokes {
            self.pageData.insertStroke(stroke)
        }
    }
    
    func removeStrokes(_ strokes : [INStroke]) {
        self.updateChangeCount(.done)
        for stroke in strokes {
            self.pageData.removeStroke(stroke)
        }
    }
    
//    func transformStrokes(_ transforms : [INStrokeTransform]) {
//        self.updateChangeCount(.done)
//        for transform in transforms {
//            self.pageData.transformStroke(transform)
//        }
//    }
}
