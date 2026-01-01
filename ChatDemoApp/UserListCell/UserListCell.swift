//
//  UserListCell.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 31/12/25.
//
import UIKit

class UserListCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var unreadBadge: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    private func setupViews() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .systemGray4
        messageLabel.textColor = .systemGray
        timeLabel.textColor = .systemGray2
        unreadBadge.layer.cornerRadius = 12.5
        unreadBadge.layer.masksToBounds = true
    }
    
    func configure(with user: User) {
        nameLabel.text = user.name
        messageLabel.text = user.lastMessage
        
        if let avatar = user.avatarImage {
            avatarImageView.image = avatar
        } else {
            // Create avatar with initials
            avatarImageView.image = createInitialsImage(from: user.name)
        }
        
        // Format time
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(user.lastMessageTime) {
            formatter.timeStyle = .short
        } else if calendar.isDateInYesterday(user.lastMessageTime) {
            timeLabel.text = "Yesterday"
            unreadBadge.isHidden = user.unreadCount == 0
            unreadBadge.text = user.unreadCount > 0 ? "\(user.unreadCount)" : ""
            return
        } else {
            formatter.dateFormat = "MMM d"
        }
        timeLabel.text = formatter.string(from: user.lastMessageTime)
        
        unreadBadge.isHidden = user.unreadCount == 0
        unreadBadge.text = user.unreadCount > 0 ? "\(user.unreadCount)" : ""
    }
    
    private func createInitialsImage(from name: String) -> UIImage? {
        let initials = name.components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let size = CGSize(width: 56, height: 56)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                y: (size.height - textSize.height) / 2,
                                width: textSize.width,
                                height: textSize.height)
            
            initials.draw(in: textRect, withAttributes: attributes)
        }
    }
}
