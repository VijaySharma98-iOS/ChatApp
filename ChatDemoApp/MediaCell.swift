//
//  MediaCell.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit

class MediaCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let checkmarkView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let videoIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iv.image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        iv.tintColor = .white
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(overlayView)
        contentView.addSubview(checkmarkView)
        checkmarkView.addSubview(numberLabel)
        contentView.addSubview(videoIconView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            checkmarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24),
            
            numberLabel.centerXAnchor.constraint(equalTo: checkmarkView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: checkmarkView.centerYAnchor),
            
            videoIconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            videoIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with image: UIImage?, isVideo: Bool = false) {
        imageView.image = image
        videoIconView.isHidden = !isVideo
    }
    
    func setSelected(_ selected: Bool, number: Int) {
        overlayView.isHidden = !selected
        checkmarkView.isHidden = !selected
        
        if selected {
            numberLabel.text = "\(number)"
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        overlayView.isHidden = true
        checkmarkView.isHidden = true
        videoIconView.isHidden = true
    }
}
