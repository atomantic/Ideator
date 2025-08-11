//
//  Item.swift
//  Ideator
//
//  Created by Adam Eivy on 8/11/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
