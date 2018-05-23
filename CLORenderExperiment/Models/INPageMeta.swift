//
//  INPageMeta.swift
//  IdeaNotes
//
//  Created by Sang Nam on 10/09/2016.
//  Copyright © 2016 Sang Nam. All rights reserved.
//

import UIKit

let KEY_THUMBNAIL   : String = "key_thumbnail"
let KEY_MODIFY_DATE : String = "key_modify_date"
let KEY_PAGE_NAME   : String = "key_page_name"

let KEY_OWNER_ID        : String = "key_owner_id"
let KEY_SECTION_ID      : String = "key_section_id"
let KEY_NOTE_ID         : String = "key_note_id"
let KEY_PDF_PAGE        : String = "key_pdf_page"
let KEY_PDF_FILE_NAME   : String = "key_pdf_file_name"


class INPageMeta : NSObject, NSCoding {

    var mDate : Date = Date()
    var thumbnail : UIImage?
    var pageName : String?
    
    var ownerId : Int = 0
    var sectionId : Int = 0
    var noteId : Int  = 0
    var pdfPage : Int = 0
    var pdfFileName : String?
    
    
    override init() {
    
    }
    
    init(pageName : String?, thumb : UIImage?, date : Date, ownerId : Int, sectionId : Int, noteId : Int, pdfPage : Int, pdfName : String?) {
        
        self.pageName = pageName
        self.thumbnail = thumb
        self.mDate = date
        
        self.ownerId = ownerId
        self.sectionId = sectionId
        self.noteId = noteId
        self.pdfPage = pdfPage
        self.pdfFileName = pdfName
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        var thumb : UIImage?
        var date : Date = Date()
        var pageName : String?
        
        var ownerId : Int = 0
        var sectionId : Int = 0
        var noteId : Int = 0
        var pdfPage : Int = 0
        var pdfFileName : String?
        
        if let d = aDecoder.decodeObject(forKey: KEY_THUMBNAIL) as? NSData {
            thumb = UIImage(data: d as Data)
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_MODIFY_DATE) as? Date {
            date = d
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_PAGE_NAME) as? String {
            pageName = d
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_OWNER_ID) as? Int {
            ownerId = d
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_SECTION_ID) as? Int {
            sectionId = d
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_NOTE_ID) as? Int {
            noteId = d
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_PDF_PAGE) as? Int {
            pdfPage = d
        }
        
        if let d = aDecoder.decodeObject(forKey: KEY_PDF_FILE_NAME) as? String {
            pdfFileName = d
        }
        
    
        self.init(pageName: pageName,thumb: thumb,date: date, ownerId: ownerId, sectionId: sectionId, noteId: noteId, pdfPage: pdfPage, pdfName: pdfFileName)
    }
    
    
    
    func encode(with aCoder: NSCoder) {
        
        if(self.thumbnail != nil) {
            let data = UIImagePNGRepresentation(self.thumbnail!)
            aCoder.encode(data, forKey: KEY_THUMBNAIL)
        }
        
        self.mDate = Date()
        aCoder.encode(self.mDate, forKey: KEY_MODIFY_DATE)
        
        if(self.pageName != nil) {
            aCoder.encode(self.pageName!, forKey: KEY_PAGE_NAME)
        }
        
        aCoder.encode(self.ownerId, forKey: KEY_OWNER_ID)
        aCoder.encode(self.sectionId, forKey: KEY_SECTION_ID)
        aCoder.encode(self.noteId, forKey: KEY_NOTE_ID)
        aCoder.encode(self.pdfPage, forKey: KEY_PDF_PAGE)
        
        if(self.pdfFileName != nil) {
            aCoder.encode(self.pdfFileName!, forKey: KEY_PDF_FILE_NAME)
        }

    }

}
