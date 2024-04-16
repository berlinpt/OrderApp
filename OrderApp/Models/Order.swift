//
//  Order.swift
//  OrderApp
//
//  Created by Berlin Thomas on 2024-04-06.
//

import Foundation

struct Order: Codable {
    var menuItems: [MenuItem]
    
    init(menuItems: [MenuItem] = []) {
        self.menuItems = menuItems
    }
}
