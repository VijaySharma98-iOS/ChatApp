//
//  ChatMessageCell.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 30/12/25.
//

import UIKit
import AVKit

// MARK: - ChatMessageCellDelegate
protocol ChatMessageCellDelegate: AnyObject {
    func didTapImage(_ image: UIImage)
    func didTapVideo(_ videoURL: URL)
}

// MARK: - Chat Message Cell
class ChatMessageCell: UITableViewCell {
    
    weak var delegate: ChatMessageCellDelegate?
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let mediaImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 30
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var mediaWidthConstraint: NSLayoutConstraint!
    private var mediaHeightConstraint: NSLayoutConstraint!
    private var messageLabelTopConstraint: NSLayoutConstraint!
    private var messageLabelTopToMediaConstraint: NSLayoutConstraint!
    private var mediaBottomConstraint: NSLayoutConstraint!
    private var timeLabelLeadingConstraint: NSLayoutConstraint!
    private var timeLabelTrailingConstraint: NSLayoutConstraint!
    
    private var currentMessage: Message?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mediaImageView.image = nil
        messageLabel.text = nil
        currentMessage = nil
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(mediaImageView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(timeLabel)
        mediaImageView.addSubview(playButton)
        
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        
        mediaWidthConstraint = mediaImageView.widthAnchor.constraint(equalToConstant: 200)
        mediaHeightConstraint = mediaImageView.heightAnchor.constraint(equalToConstant: 200)
        
        // Two different top constraints for messageLabel
        messageLabelTopConstraint = messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8)
        messageLabelTopToMediaConstraint = messageLabel.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 8)
        
        // Bottom constraint for media when there's no caption
        mediaBottomConstraint = mediaImageView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -4)
        
        // Time label constraints
        timeLabelLeadingConstraint = timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12)
        timeLabelTrailingConstraint = timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            mediaImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4),
            mediaImageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),
            mediaImageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4),
            
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -4),
            
            playButton.centerXAnchor.constraint(equalTo: mediaImageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: mediaImageView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60),
            
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4)
        ])
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(mediaTapped))
        mediaImageView.addGestureRecognizer(imageTap)
        
        playButton.addTarget(self, action: #selector(mediaTapped), for: .touchUpInside)
    }
    
    func configure(with message: Message) {
        currentMessage = message
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Deactivate all dynamic constraints first
        messageLabelTopConstraint.isActive = false
        messageLabelTopToMediaConstraint.isActive = false
        mediaWidthConstraint.isActive = false
        mediaHeightConstraint.isActive = false
        mediaBottomConstraint.isActive = false
        timeLabelLeadingConstraint.isActive = false
        timeLabelTrailingConstraint.isActive = false
        
        // Reset visibility
        messageLabel.isHidden = false
        mediaImageView.isHidden = true
        playButton.isHidden = true
        mediaImageView.backgroundColor = .clear
        
        switch message.type {
        case .text(let text):
            messageLabel.text = text
            messageLabelTopConstraint.isActive = true
            
        case .image(let image, let caption):
            mediaImageView.isHidden = false
            mediaImageView.image = image
            
            // Calculate aspect ratio
            let aspectRatio = image.size.height / image.size.width
            let maxWidth: CGFloat = 200
            let maxHeight: CGFloat = 300
            
            let width = min(image.size.width, maxWidth)
            let height = min(width * aspectRatio, maxHeight)
            
            mediaWidthConstraint.constant = width
            mediaHeightConstraint.constant = height
            mediaWidthConstraint.isActive = true
            mediaHeightConstraint.isActive = true
            
            if let caption = caption, !caption.isEmpty {
                messageLabel.text = caption
                messageLabelTopToMediaConstraint.isActive = true
            } else {
                messageLabel.isHidden = true
                mediaBottomConstraint.isActive = true
            }
            
        case .video(_, let thumbnail, let caption):
            mediaImageView.isHidden = false
            playButton.isHidden = false
            
            if let thumbnail = thumbnail {
                mediaImageView.image = thumbnail
                
                let aspectRatio = thumbnail.size.height / thumbnail.size.width
                let maxWidth: CGFloat = 200
                let maxHeight: CGFloat = 300
                
                let width = min(thumbnail.size.width, maxWidth)
                let height = min(width * aspectRatio, maxHeight)
                
                mediaWidthConstraint.constant = width
                mediaHeightConstraint.constant = height
            } else {
                mediaImageView.backgroundColor = .systemGray5
                mediaWidthConstraint.constant = 200
                mediaHeightConstraint.constant = 200
            }
            
            mediaWidthConstraint.isActive = true
            mediaHeightConstraint.isActive = true
            
            if let caption = caption, !caption.isEmpty {
                messageLabel.text = caption
                messageLabelTopToMediaConstraint.isActive = true
            } else {
                messageLabel.isHidden = true
                mediaBottomConstraint.isActive = true
            }
        }
        
        // Configure bubble appearance
        if message.isFromCurrentUser {
            bubbleView.backgroundColor = UIColor(hex: "#d9fdd4")
            messageLabel.textColor = .black
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            timeLabel.textAlignment = .right
            timeLabelTrailingConstraint.isActive = true
        } else {
            bubbleView.backgroundColor = .white
            messageLabel.textColor = .black
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            timeLabel.textAlignment = .left
            timeLabelLeadingConstraint.isActive = true
        }
    }
    
    @objc private func mediaTapped() {
        guard let message = currentMessage else { return }
        
        switch message.type {
        case .image(let image, _):
            delegate?.didTapImage(image)
        case .video(let url, _, _):
            delegate?.didTapVideo(url)
        default:
            break
        }
    }
}
