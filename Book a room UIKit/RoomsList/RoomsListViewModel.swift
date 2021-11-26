//
//  RoomsListViewModel.swift
//  Book a room UIKit
//
//  Created by Felix Fischer on 26/11/2021.
//

import Foundation
import Combine
import CoreData
import UIKit

class RoomsListViewModel: NSObject {
    
    enum Status {
        case loading
        case loaded
        case error
    }
    
    private let service: RoomsServiceProtocol
    private var cancellables: [AnyCancellable] = []
    
    weak var fetchControllerDelegate: NSFetchedResultsControllerDelegate?
    
    let status = CurrentValueSubject<Status, Never>(.loading)
    
    init(service: RoomsServiceProtocol) {
        self.service = service
    }
    
    func onAppear() {
        loadRooms()
    }
    
    func book(_ room: Room) -> AnyPublisher<Bool, Error> {
        service.book(room)
    }
    
    private func fetch() {
        let fetchController = CoreDataStack.shared.roomsFetchedResultsController
        fetchController.delegate = fetchControllerDelegate
        try? fetchController.performFetch()
    }
    
    func loadRooms() {
        status.send(.loading)
        service.fetchRooms().receive(on: RunLoop.main).sink { result in
            if case let .failure(_) = result {
                self.status.send(.error)
                // TODO: Better error handling
            }
        } receiveValue: { _ in
            self.fetch()
            self.status.send(.loaded)
        }.store(in: &cancellables)
    }
    
}

extension RoomsListViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
    }
}


//@available(iOS 13.0, *)

