//
//  MediaPreviewItemView.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit

class MediaPreviewItemView: UIView {
    
    var onRemove: (() -> Void)?
    
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let overlayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let playIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        iv.image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let pdfIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iv.image = UIImage(systemName: "doc.fill", withConfiguration: config)
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let pdfNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = 8
        clipsToBounds = true
        backgroundColor = .systemGray6
        
        addSubview(imageView)
        addSubview(overlayView)
        overlayView.addSubview(overlayLabel)
        addSubview(removeButton)
        addSubview(playIconView)
        addSubview(pdfIconView)
        addSubview(pdfNameLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            overlayLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            overlayLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            
            removeButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            removeButton.widthAnchor.constraint(equalToConstant: 24),
            removeButton.heightAnchor.constraint(equalToConstant: 24),
            
            playIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 40),
            playIconView.heightAnchor.constraint(equalToConstant: 40),
            
            pdfIconView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            pdfIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            pdfIconView.widthAnchor.constraint(equalToConstant: 32),
            pdfIconView.heightAnchor.constraint(equalToConstant: 32),
            
            pdfNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            pdfNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            pdfNameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            pdfNameLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with item: MediaItem, showOverlay: Bool = false, overlayCount: Int = 0) {
        // Reset all icons
        playIconView.isHidden = true
        pdfIconView.isHidden = true
        pdfNameLabel.isHidden = true
        overlayView.isHidden = true
        
        switch item {
        case .image(let image, _):
            imageView.image = image
            
        case .video(_, let thumbnail, _):
            if let thumbnail = thumbnail {
                imageView.image = thumbnail
            }
            playIconView.isHidden = false
            
        case .pdf(_, let thumbnail, let name, _):
            if let thumbnail = thumbnail {
                imageView.image = thumbnail
            }
            pdfIconView.isHidden = false
            pdfNameLabel.isHidden = false
            pdfNameLabel.text = name
        }
        
        // Show overlay if needed
        if showOverlay && overlayCount > 0 {
            overlayView.isHidden = false
            overlayLabel.text = "+\(overlayCount)"
        }
    }
    
    @objc private func removeTapped() {
        onRemove?()
    }
}
