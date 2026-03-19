//
//  Item.swift
//  Glosc 2fa
//
//  Created by XiaoM on 2026/3/19.
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
