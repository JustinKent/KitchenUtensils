//
//  Utensil.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import Foundation
import SwiftData

@Model
final class Utensil {
    @Attribute(.unique) var id: UUID
    var name: String
    var creationDate: Date
    
    init(id: UUID = UUID(),
         name: String,
         creationDate: Date) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
    }
}
