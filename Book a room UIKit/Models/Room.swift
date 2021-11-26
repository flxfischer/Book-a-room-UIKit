//
//  File.swift
//  Book a room UIKit
//
//  Created by Felix Fischer on 26/11/2021.
//

import Foundation
import CoreData

enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}

class Room: NSManagedObject, Decodable {
    enum CodingKeys: CodingKey {
        case name, spots, thumbnail
    }
    
    required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        
        self.init(context: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.spots = try container.decode(Int32.self, forKey: .spots)
        let thumbnail = try container.decode(String.self, forKey: .thumbnail)
        self.thumbnail = URL(string: thumbnail)
    }
}

extension CodingUserInfoKey {
  static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
