//
//  ViewController.swift
//  Book a room UIKit
//
//  Created by Felix Fischer on 26/11/2021.
//

import UIKit
import CoreData
import Combine

class RoomsListViewController: UIViewController {
    
    var viewModel: RoomsListViewModel?
    private var cancellables: [AnyCancellable] = []
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadRooms), for: .primaryActionTriggered)
        return control
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(RoomsListCollectionViewCell.self, forCellWithReuseIdentifier: RoomsListCollectionViewCell.cellIdentifier)
        collectionView.refreshControl = refreshControl
        return collectionView
    }()
    
    private lazy var collectionViewLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 16
        let itemWidth = view.frame.size.width - (2 * padding)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth/1.5)
        layout.minimumLineSpacing = 32
        return layout
    }()
    
    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID> = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>(collectionView: collectionView) { collectionView, indexPath, objectID in
        guard let room = try? CoreDataStack.shared.persistentContainer.viewContext.existingObject(with: objectID) as? Room else {
            fatalError("Managed object should be available")
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RoomsListCollectionViewCell.cellIdentifier, for: indexPath) as? RoomsListCollectionViewCell else {
            fatalError("Cell should be available")
        }
        cell.room = room
        cell.buttonPressed = {
            self.viewModel?.book(room).receive(on: RunLoop.main).sink(receiveCompletion: { result in
                if case let .failure(_) = result {
                    // TODO: Handle error
                }
            }, receiveValue: { success in
                if success { room.spots -= 1 }
                self.showBookingAlert(success)
            }).store(in: &self.cancellables)
        }
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Book a room"
        
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
        
        viewModel?.status.receive(on: RunLoop.main).sink(receiveValue: { status in
            switch status {
            case .loading:
                self.refreshControl.beginRefreshing()
                self.collectionView.isHidden = true
            case .loaded:
                self.refreshControl.endRefreshing()
                self.collectionView.isHidden = false
            case .error:
                self.refreshControl.endRefreshing()
                self.collectionView.isHidden = true
            }
        }).store(in: &cancellables)
        
        viewModel?.onAppear()
    }
    
    private func showBookingAlert(_ success: Bool) {
        let title = success ? "Booking successful" : "Booking not successful"
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true)
    }
    
    @objc private func loadRooms() {
        viewModel?.loadRooms()
    }
}

extension RoomsListViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = diffableDataSource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)
    
        diffableDataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: true)
    }
}
