//
//  INPage.swift
//  IdeaNotes
//
//  Created by Sang Nam on 28/06/2016.
//  Copyright © 2016 Sang Nam. All rights reserved.
//

import UIKit
// real A4 size: 21.0 x 29.7 cm ~ ratio: 1.414
let A4Ratio : CGFloat = 1.414
let A4PaperSize : CGSize = CGSize(width: 500, height: 500 * A4Ratio)
let A4DotCodeSize : CGSize = CGSize(width: 100, height: 100 * A4Ratio)

//class INImageData : NSObject, NSCoding {
//
//    let KEY_IMAGEDATA_
//    var image : UIImage?
//    var rect : CGRect = .zero
//    var rotation : CGFloat = 0.0
//
//    override init() {
//    }
//
//    init(image : UIImage?, rect : CGRect, rotation : CGFloat) {
//        self.image = image
//        self.rect = rect
//        self.rotation = rotation
//    }
//
//    required convenience init?(coder aDecoder: NSCoder) {
//
//        var image : UIImage?
//        var rect : Date = Date()
//        var rotation : String?
//
//        if let d = aDecoder.decodeObject(forKey: KEY_THUMBNAIL) as? NSData {
//            thumb = UIImage(data: d as Data)
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_MODIFY_DATE) as? Date {
//            date = d
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_PAGE_NAME) as? String {
//            pageName = d
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_OWNER_ID) as? Int {
//            ownerId = d
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_SECTION_ID) as? Int {
//            sectionId = d
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_NOTE_ID) as? Int {
//            noteId = d
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_PDF_PAGE) as? Int {
//            pdfPage = d
//        }
//
//        if let d = aDecoder.decodeObject(forKey: KEY_PDF_FILE_NAME) as? String {
//            pdfFileName = d
//        }
//
//
//        self.init(pageName: pageName,thumb: thumb,date: date, ownerId: ownerId, sectionId: sectionId, noteId: noteId, pdfPage: pdfPage, pdfName: pdfFileName)
//    }
//
//
//
//    func encode(with aCoder: NSCoder) {
//
//        if(self.thumbnail != nil) {
//            let data = UIImagePNGRepresentation(self.thumbnail!)
//            aCoder.encode(data, forKey: KEY_THUMBNAIL)
//        }
//
//        self.mDate = Date()
//        aCoder.encode(self.mDate, forKey: KEY_MODIFY_DATE)
//
//        if(self.pageName != nil) {
//            aCoder.encode(self.pageName!, forKey: KEY_PAGE_NAME)
//        }
//
//        aCoder.encode(self.ownerId, forKey: KEY_OWNER_ID)
//        aCoder.encode(self.sectionId, forKey: KEY_SECTION_ID)
//        aCoder.encode(self.noteId, forKey: KEY_NOTE_ID)
//        aCoder.encode(self.pdfPage, forKey: KEY_PDF_PAGE)
//
//        if(self.pdfFileName != nil) {
//            aCoder.encode(self.pdfFileName!, forKey: KEY_PDF_FILE_NAME)
//        }
//
//    }
//}

@objc class INPage: NSObject, NSCoding {
    
    static let kTHUMBNAIL_FOLDER_NAME : String = "PageImages"
    
    fileprivate var strokes =  [INStroke]()
    
    var timeDisordered = false
    
    init(strokes : [INStroke]) {
        
        self.strokes = strokes
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let strokesData = aDecoder.decodeObject(forKey: "strokes") as? NSData
        else {
            return nil
        }
        
        let (strokes,recoverSave) = INPage.readPage(strokesData)
        self.init(strokes: strokes)
        self.timeDisordered = recoverSave
    }
    
    func encode(with aCoder: NSCoder) {
        
        let pageData = writePage(true)
        aCoder.encode(pageData, forKey: "strokes")
    }
    
    func copy(with zone: NSZone? = nil) -> INPage {
        
        var copyStrokes = [INStroke]()
        for stroke in strokes {
            let copyStroke = stroke.copyStroke()
            copyStrokes.append(copyStroke)
        }
        let copy = INPage(strokes: copyStrokes)
        
        return copy
    }
    
    
    static func readPage(_ pageData : NSData) -> ([INStroke],Bool) {
        
        var position : Int = 0
        var length : Int = 0
        
        var strokeCount : Int = 0
        length = MemoryLayout<UInt32>.size;
        let range : NSRange = NSRange.init(location: position, length: length)
        pageData.getBytes(&strokeCount, range: range)
        
        var strokes = [INStroke]()
        var strokes1 = [INStroke]()
        var lastTime : UInt64 = 0
        var shouldReorder : Bool = false
        var noDel = 0
        
        for _ in 0 ..< strokeCount {
            let stroke = INStroke()
            position += length
            length = stroke.readStroke(pageData, pos: position)
            guard stroke.dotCount > 3 else {
                noDel += 1
                print("THIS STROKE MUST BE DELETED")
                continue
            }

            if(stroke.startTime <= lastTime) { shouldReorder = true }
            lastTime = stroke.startTime
            strokes.append(stroke)
        }
        if(shouldReorder) {
            print("NOW RE-SORT PAGES STROKES")
            lastTime = 0
            strokes = strokes.sorted(by: sortFunc)
            for st in strokes {
                if(st.startTime == lastTime) {
                    noDel += 1
                    continue
                }
                lastTime = st.startTime
                strokes1.append(st)
            }
        } else {
            strokes1 = strokes
        }
        if(noDel > 0) {
            print("THIS PAGE HAS TIMESTAMP DIS-ORDER == \(strokeCount) - \(noDel)(*ignored) == \(strokes.count)")
        }
        return (strokes1,(noDel>0))
    }
    
    class func sortFunc(stroke1: INStroke, stroke2: INStroke) -> Bool {
        return stroke1.startTime < stroke2.startTime
    }
    
    func writePage(_ imgSaving : Bool) -> Data {
        
        self.timeDisordered = false
        let pageData = NSMutableData()
        var strokeCount = self.strokes.count
        pageData.append(&strokeCount, length: MemoryLayout<Int32>.size)
        
        for stroke in strokes {
            let strokeData = stroke.writeStroke()
            pageData.append(strokeData as Data)
        }

        return pageData as Data
    }
    
    
    func removeStroke(_ stroke : INStroke) {
        var index = 0
        for st in strokes {
            
            if(stroke.startTime == st.startTime) { break }
            index = index + 1
        }
        if(index < strokes.count) {
            strokes.remove(at: index)
        }
    }
    
    func removeStroke(at index : Int) {
        
        strokes.remove(at: index)
    }
    
    func addStroke(_ stroke : INStroke) {
        
        strokes.append(stroke)
    }
    
    func insertStroke(_ stroke : INStroke) {
        
        var index = 0
        for st in strokes {
            if(stroke.startTime == st.startTime) {
                //print("INSERT STROKE - SOMETHING WRONG TIME SHOULD NOT BE SAME!!!!")
                return
            }
            if(stroke.startTime < st.startTime) { break }
            index = index + 1
        }
        strokes.insert(stroke, at: index)
    }
    
//    func transformStroke(_ transform : INStrokeTransform) {
//        
//        for st in strokes {
//            if(st.startTime == transform.timestamp) {
//               // check color
//                if(st.color.toInt() != transform.color.toInt()) {
//                    st.color = transform.color
//                }
//                if(st.thickness != transform.thickness) {
//                    st.thickness = transform.thickness
//                }
//                
//                
//                if(transform.offset != .zero) {
//                    st.translate(offset: transform.offset)
//                }
//                
//            }
//        }
//    }
    
    func strokeCount() -> Int {
        return strokes.count
    }
    
    func getStroke(at : Int) -> INStroke {
        return strokes[at]
    }
    
    func getStrokes() -> [INStroke] {
        return strokes
    }
    
    func getLastStroke() -> INStroke {
        return strokes[strokes.count - 1]
    }
    

    
    func createThumbnail(pageUUID : String) -> UIImage {
        
        let thumbnail = self.renderPage(A4PaperSize)
//        INCacheStore.shared.setImage(image: thumbnail, forKey: pageUUID)
        
        return thumbnail
    }
    
    func renderPage(_ size : CGSize) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size,true,1.0)
        let context : CGContext = UIGraphicsGetCurrentContext()!
        
        let rect = UIBezierPath(rect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height)))
//        UIColor(white: 0.98, alpha: 1).setFill()
        UIColor.white.setFill()
        rect.fill()
        
        let normalizer = max(size.width,size.height)
        let dotNormalizer = max(A4DotCodeSize.width,A4DotCodeSize.height)
        
        for stroke in strokes {
            
//            stroke.renderStroke(normalizer/dotNormalizer, offset: CGPoint.zero)
            stroke.drawStroke(ctx: context)
        }
        
        let pageImage = UIGraphicsGetImageFromCurrentImageContext()
        
        context.flush()
        UIGraphicsEndImageContext()
        
        return pageImage!
    }
    
}
