//
//  INDBManager.swift
//  IdeaNotes
//
//  Created by Sang Nam on 10/1/17.
//  Copyright © 2017 Sang Nam. All rights reserved.
//

import UIKit
import CoreData

class PTDBManager: NSObject {

    
    static let sharedInstance = PTDBManager()
    
    private lazy var privateMoc : NSManagedObjectContext = {
        
        var context : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.psc
        return context
    }()
    
    public lazy var moc: NSManagedObjectContext = {
        
        var context: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = self.privateMoc
        return context
    }()
    
    private lazy var psc : NSPersistentStoreCoordinator = {
        
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let storeURL = documentURL.appendingPathComponent("PaperTube.sqlite")
        
        let options = [ NSMigratePersistentStoresAutomaticallyOption : true,
                        NSInferMappingModelAutomaticallyOption : true ]
        
        let _psc : NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.mom)
        do {
            try _psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            NSLog("Error when creating persistent store \(error)")
            fatalError()
        }
        return _psc
    }()
    
    private lazy var mom: NSManagedObjectModel = {
        var modelPath = Bundle.main.path(forResource: "DBModel", ofType: "momd")
        var modelURL = NSURL.fileURL(withPath: modelPath!)
        var model = NSManagedObjectModel(contentsOf: modelURL)!
        
        return model
    }()
    
    
    private override init() {
        super.init()

    }
    
    
    public func saveContext(wait: Bool) {
        
        let moc : NSManagedObjectContext = self.moc
        let privateMoc : NSManagedObjectContext = self.privateMoc
        
        if(moc.hasChanges) {
            moc.performAndWait({
                do {
                    try moc.save()
                } catch {
                    
                }
            })
        }
        
        let savePrivate: () -> Void = { 
            do {
                try privateMoc.save()
            } catch {
                
            }
        }
        
        if(privateMoc.hasChanges) {
            if(wait) {
                privateMoc.performAndWait(savePrivate)
                
            } else {
                privateMoc.perform(savePrivate)
            }
        }
    }
    
    
}
