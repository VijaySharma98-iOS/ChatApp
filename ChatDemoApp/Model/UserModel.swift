//
//  UserModel.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 31/12/25.
//

import UIKit

enum MediaItem {
    case image(UIImage, identifier: String = UUID().uuidString)
    case video(URL, thumbnail: UIImage?, identifier: String = UUID().uuidString)
    case pdf(URL, thumbnail: UIImage?, name: String, identifier: String = UUID().uuidString)
    
    var id: String {
        switch self {
        case .image(_, let identifier):
            return identifier
        case .video(_, _, let identifier):
            return identifier
        case .pdf(_, _, _, let identifier):
            return identifier
        }
    }
}

 //MARK: - MediaItem to MessageType Conversion
//extension MediaItem {
//    func toMessageType(caption: String? = nil) -> MessageType {
//        switch self {
//        case .image(let image, _):
//            return .image(image, caption)
//        case .video(let url, let thumbnail, _):
//            return .video(url, thumbnail, caption)
//        case .pdf(let url, let thumbnail, let name, _):
//            return .pdf(url, thumbnail, name)
//        }
//    }
//}


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

// MARK: - Message Type Enum
enum MessageType {
    case text(String)
    case image(UIImage, String?) // image, optional caption
    case video(URL, UIImage?, String?) // url, thumbnail, optional caption
    case audio(URL, TimeInterval) // url, duration
    case pdf(URL, UIImage?, String) // url, thumbnail, filename
}

// MARK: - Message Model
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
        case .pdf(_, _, let filename):
            return "📄 \(filename)"
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
    
    var isPDFMessage: Bool {
        if case .pdf = type {
            return true
        }
        return false
    }
    
    var hasMediaContent: Bool {
        return isImageMessage || isVideoMessage || isAudioMessage || isPDFMessage
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
            ),
            User(
                id: "4",
                name: "Alice Williams",
                avatarImage: nil,
                lastMessage: "📄 Document.pdf",
                lastMessageTime: Date().addingTimeInterval(-10800),
                unreadCount: 0
            ),
            User(
                id: "5",
                name: "Mike Brown",
                avatarImage: nil,
                lastMessage: "🎤 Voice message (0:15)",
                lastMessageTime: Date().addingTimeInterval(-14400),
                unreadCount: 3
            )
        ]
    }
}

// MARK: - Date Formatting Helper
extension Date {
    func chatTimeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: self)
        }
    }
}
