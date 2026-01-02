//
//  UserModel.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 31/12/25.
//

import UIKit

// MARK: - User Model
struct User {
    let id: String
    let name: String
    let avatarImage: UIImage?
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    
    init(id: String, name: String, avatarImage: UIImage? = nil, lastMessage: String, lastMessageTime: Date, unreadCount: Int = 0) {
        self.id = id
        self.name = name
        self.avatarImage = avatarImage
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}

// MARK: - Message Model
enum MessageType {
    case text(String)
    case image(UIImage, String?)
    case video(URL, UIImage?, String?)
    case audio(URL, TimeInterval)
}

struct Message {
    let id: String
    let type: MessageType
    let isFromCurrentUser: Bool
    let timestamp: Date
    
    var text: String? {
        switch type {
        case .text(let content):
            return content
        case .image(_, let caption):
            return caption
        case .video(_, _, let caption):
            return caption
        case .audio(_, let duration):
            // Return a formatted duration string for audio messages
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "🎤 Voice message (\(minutes):\(String(format: "%02d", seconds)))"
        }
    }
    
    init(id: String = UUID().uuidString, type: MessageType, isFromCurrentUser: Bool, timestamp: Date) {
        self.id = id
        self.type = type
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
    }
}

// MARK: - Helper Extensions
extension Message {
    var isTextMessage: Bool {
        if case .text = type {
            return true
        }
        return false
    }
    
    var isImageMessage: Bool {
        if case .image = type {
            return true
        }
        return false
    }
    
    var isVideoMessage: Bool {
        if case .video = type {
            return true
        }
        return false
    }
    
    var isAudioMessage: Bool {
        if case .audio = type {
            return true
        }
        return false
    }
    
    var hasMediaContent: Bool {
        return isImageMessage || isVideoMessage || isAudioMessage
    }
}

// MARK: - Sample Data Helper
extension User {
    static func sampleUsers() -> [User] {
        return [
            User(
                id: "1",
                name: "John Doe",
                avatarImage: nil,
                lastMessage: "Hey, how are you?",
                lastMessageTime: Date().addingTimeInterval(-300),
                unreadCount: 2
            ),
            User(
                id: "2",
                name: "Jane Smith",
                avatarImage: nil,
                lastMessage: "See you tomorrow!",
                lastMessageTime: Date().addingTimeInterval(-3600),
                unreadCount: 0
            ),
            User(
                id: "3",
                name: "Bob Johnson",
                avatarImage: nil,
                lastMessage: "Thanks for your help 👍",
                lastMessageTime: Date().addingTimeInterval(-7200),
                unreadCount: 1
            )
        ]
    }
}
