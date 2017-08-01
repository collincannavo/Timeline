//
//  CloudKitSyncable.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/20/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//

import Foundation
import CloudKit



protocol CloudKitSyncable {

    init?(record: CKRecord)
    
    var cloudKitRecordID: CKRecordID? { get set }
    var recordType: String { get }
    
}

extension CloudKitSyncable {
    
    var isSynced: Bool {
       return cloudKitRecordID != nil
    }
    
    var cloudKitReference: CKReference? {
        guard let cloudKitRecordID = cloudKitRecordID else { return nil }
        
        return CKReference(recordID: cloudKitRecordID, action: .none)
        
    }
    
}



