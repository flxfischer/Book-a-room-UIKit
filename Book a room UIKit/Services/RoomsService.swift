//
//  RoomsService.swift
//  Book a room UIKit
//
//  Created by Felix Fischer on 26/11/2021.
//

import Foundation
import Combine
import SwiftUI

protocol RoomsServiceProtocol {
    func fetchRooms() -> AnyPublisher<Void, Error>
    func book(_ room: Room) -> AnyPublisher<Bool, Error>
}

class RoomsService: RoomsServiceProtocol {
    
    enum RoomsServiceError: Error {
        case appDelegateNotFound
    }
    
    private let roomsUrl = URL(string: "https://wetransfer.github.io/rooms.json")!
    private let bookUrl = URL(string: "https://wetransfer.github.io/bookRoom.json")!
    private var cancellables: [AnyCancellable] =  []
    
    func fetchRooms() -> AnyPublisher<Void, Error> {
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = CoreDataStack.shared.persistentContainer.viewContext
        
        let publisher = PassthroughSubject<Void, Error>()
        
        URLSession.shared
            .dataTaskPublisher(for: roomsUrl)
            .map(\.data)
            .decode(type: RoomsResult.self, decoder: decoder)
            .sink(receiveCompletion: { completion in
                publisher.send(completion: completion)
            }, receiveValue: { _ in
                CoreDataStack.shared.saveContext()
                publisher.send()
            })
            .store(in: &cancellables)
        
        return publisher.eraseToAnyPublisher()
    }
    
    func book(_ room: Room) -> AnyPublisher<Bool, Error> {
        return URLSession.shared
            .dataTaskPublisher(for: bookUrl)
            .map(\.data)
            .decode(type: BookResult.self, decoder: JSONDecoder())
            .map(\.success)
            .eraseToAnyPublisher()
    }
}

struct RoomsResult: Decodable {
    let rooms: [Room]
}

struct BookResult: Decodable {
    let success: Bool
}
