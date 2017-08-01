//
//  SearchableRecord.swift
//  Timeline
//
//  Created by Collin Cannavo on 6/19/17.
//  Copyright © 2017 Collin Cannavo. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    func matches(searchTerm: String) -> Bool

}
