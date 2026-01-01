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
    case image(UIImage, String?) // Image and optional caption
    case video(URL, UIImage?, String?) // URL, optional thumbnail, and optional caption
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
        }
    }
    
    init(id: String = UUID().uuidString, type: MessageType, isFromCurrentUser: Bool, timestamp: Date) {
        self.id = id
        self.type = type
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
    }
}
