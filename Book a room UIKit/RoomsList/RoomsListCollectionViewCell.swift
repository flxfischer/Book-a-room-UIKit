//
//  RoomsListCollectionViewCell.swift
//  Book a room UIKit
//
//  Created by Felix Fischer on 26/11/2021.
//

import Foundation
import UIKit
import Kingfisher
import Combine

class RoomsListCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "RoomsListCollectionViewCell"
    
    private var cancellables: [AnyCancellable] = []
    
    var room: Room? {
        didSet {
            room?.publisher(for: \.name).receive(on: RunLoop.main).sink {
                self.titleLabel.text = $0
            }.store(in: &cancellables)
            room?.publisher(for: \.thumbnail).receive(on: RunLoop.main).sink {
                self.image.kf.setImage(with: $0)
            }.store(in: &cancellables)
            room?.publisher(for: \.spots).receive(on: RunLoop.main).sink {
                self.spotsLabel.text = "\($0) spots remaining"
                self.bookButton.isEnabled = $0 != 0
            }.store(in: &cancellables)
        }
    }
    
    var buttonPressed: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func prepareForReuse() {
        cancellables.removeAll()
        super.prepareForReuse()
    }
    
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 11
        image.layer.masksToBounds = true
        image.contentMode = .scaleAspectFill
        return image
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private lazy var spotsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.mainColor
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private lazy var bookButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Book!", for: .normal)
        button.backgroundColor = UIColor.mainColor
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.layer.cornerRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.addTarget(self, action: #selector(objcButtonPressed), for: .primaryActionTriggered)
        return button
    }()
    
    private func setup() {
        let titleSpotsStack = UIStackView(arrangedSubviews: [titleLabel, spotsLabel])
        titleSpotsStack.axis = .vertical
        
        let textButtonStack = UIStackView(arrangedSubviews: [titleSpotsStack, bookButton])
        textButtonStack.axis = .horizontal
        textButtonStack.spacing = 8
        textButtonStack.alignment = .top
        
        let mainStack = UIStackView(arrangedSubviews: [image, textButtonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    
    
    @objc private func objcButtonPressed() {
        buttonPressed?()
    }
    
}
