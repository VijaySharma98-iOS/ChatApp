//
//  ChatViewModel.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import Foundation
import UIKit

// MARK: - ChatViewModel Protocol
protocol ChatViewModelProtocol: AnyObject {
    var messages: [Message] { get }
    var pendingMediaItems: [MediaItem] { get }
    
    func sendText(_ text: String)
    func sendAudio(url: URL, duration: TimeInterval)
    func sendPDF(url: URL, thumbnail: UIImage?, fileName: String)
    func sendPendingMedia(caption: String?)
    func addPendingMedia(_ items: [MediaItem])
    func removePendingMedia(id: String)
    func clearPendingMedia()
    
    var onMessagesUpdated: (() -> Void)? { get set }
    var onPendingMediaUpdated: (() -> Void)? { get set }
}

// MARK: - ChatViewModel
final class ChatViewModel: ChatViewModelProtocol {
    
    // MARK: - State
    private(set) var messages: [Message] = [] {
        didSet { onMessagesUpdated?() }
    }
    
    private(set) var pendingMediaItems: [MediaItem] = [] {
        didSet { onPendingMediaUpdated?() }
    }
    
    // MARK: - Callbacks
    var onMessagesUpdated: (() -> Void)?
    var onPendingMediaUpdated: (() -> Void)?
    
    // MARK: - Dependencies
    private let messageService: MessageService
    private let responseSimulator: ResponseSimulator
    
    // MARK: - Init
    init(
        messageService: MessageService = DefaultMessageService(),
        responseSimulator: ResponseSimulator = DefaultResponseSimulator()
    ) {
        self.messageService = messageService
        self.responseSimulator = responseSimulator
        loadInitialMessages()
    }
    
    // MARK: - Public API
    
    func sendText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let message = messageService.createTextMessage(trimmed)
        appendMessage(message)
    }
    
    func sendAudio(url: URL, duration: TimeInterval) {
        let message = messageService.createAudioMessage(url: url, duration: duration)
        appendMessage(message)
    }
    
    func sendPDF(url: URL, thumbnail: UIImage?, fileName: String) {
        // Create a single MediaItem for the PDF and convert to MessageType using existing flow
        let mediaItem = MediaItem.pdf(url, thumbnail: thumbnail, name: fileName)
        let messages = messageService.createMediaMessages(from: [mediaItem], caption: nil)
        if let message = messages.first {
            appendMessage(message)
        }
    }
    
    func sendPendingMedia(caption: String?) {
        guard !pendingMediaItems.isEmpty else { return }
        
        let trimmedCaption = caption?.trimmingCharacters(in: .whitespaces)
        let finalCaption = trimmedCaption?.isEmpty == false ? trimmedCaption : nil
        
        let newMessages = messageService.createMediaMessages(
            from: pendingMediaItems,
            caption: finalCaption
        )
        
        messages.append(contentsOf: newMessages)
        clearPendingMedia()
        simulateResponse()
    }
    
    func addPendingMedia(_ items: [MediaItem]) {
        pendingMediaItems.append(contentsOf: items)
    }
    
    func removePendingMedia(id: String) {
        pendingMediaItems.removeAll { $0.id == id }
    }
    
    func clearPendingMedia() {
        pendingMediaItems.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func appendMessage(_ message: Message) {
        messages.append(message)
        simulateResponse()
    }
    
    private func simulateResponse() {
        responseSimulator.generateResponse { [weak self] message in
            self?.messages.append(message)
        }
    }
    
    private func loadInitialMessages() {
        messages = messageService.loadSampleMessages()
    }
}

// MARK: - Message Service Protocol
protocol MessageService {
    func createTextMessage(_ text: String) -> Message
    func createAudioMessage(url: URL, duration: TimeInterval) -> Message
    func createMediaMessages(from items: [MediaItem], caption: String?) -> [Message]
    func loadSampleMessages() -> [Message]
}

// MARK: - Default Message Service
final class DefaultMessageService: MessageService {
    
    func createTextMessage(_ text: String) -> Message {
        Message(
            type: .text(text),
            isFromCurrentUser: true,
            timestamp: Date()
        )
    }
    
    func createAudioMessage(url: URL, duration: TimeInterval) -> Message {
        Message(
            type: .audio(url, duration),
            isFromCurrentUser: true,
            timestamp: Date()
        )
    }
    
    func createMediaMessages(from items: [MediaItem], caption: String?) -> [Message] {
        items.enumerated().map { index, item in
            let itemCaption = (index == 0) ? caption : nil
            let messageType = item.toMessageType(caption: itemCaption)
            
            return Message(
                type: messageType,
                isFromCurrentUser: true,
                timestamp: Date()
            )
        }
    }
    
    func loadSampleMessages() -> [Message] {
        let baseTime = Date().addingTimeInterval(-3600)
        
        return [
            Message(
                type: .text("Hey! How are you?"),
                isFromCurrentUser: false,
                timestamp: baseTime
            ),
            Message(
                type: .text("I'm doing great, thanks! How about you?"),
                isFromCurrentUser: true,
                timestamp: baseTime.addingTimeInterval(100)
            ),
            Message(
                type: .text("That's amazing! 😍"),
                isFromCurrentUser: true,
                timestamp: baseTime.addingTimeInterval(300)
            ),
            Message(
                type: .text("Pretty good! Just working on a new project."),
                isFromCurrentUser: false,
                timestamp: baseTime.addingTimeInterval(400)
            ),
            Message(
                type: .text("That sounds exciting! What kind of project?"),
                isFromCurrentUser: true,
                timestamp: baseTime.addingTimeInterval(500)
            )
        ]
    }
}

// MARK: - Response Simulator Protocol
protocol ResponseSimulator {
    func generateResponse(completion: @escaping (Message) -> Void)
}

// MARK: - Default Response Simulator
final class DefaultResponseSimulator: ResponseSimulator {
    
    private let responseGenerator: ResponseGenerator
    
    init(responseGenerator: ResponseGenerator = RandomResponseGenerator()) {
        self.responseGenerator = responseGenerator
    }
    
    func generateResponse(completion: @escaping (Message) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let message = self.responseGenerator.generateMessage()
            completion(message)
        }
    }
}

// MARK: - Response Generator Protocol
protocol ResponseGenerator {
    func generateMessage() -> Message
}

// MARK: - Random Response Generator
final class RandomResponseGenerator: ResponseGenerator {
    
    private let textResponses = [
        "That's interesting!",
        "Tell me more about that.",
        "I see what you mean.",
        "Thanks for sharing!",
        "Got it!",
        "Absolutely!",
        "I understand.",
        "Makes sense."
    ]
    
    private let imageCaptions = [
        "Check this out!",
        "Look at this!",
        "Amazing, right?",
        nil
    ]
    
    private let videoCaptions = [
        "Watch this!",
        "Cool video!",
        nil
    ]
    
    func generateMessage() -> Message {
        let responseType = Int.random(in: 0...10)
        let messageType: MessageType
        
        switch responseType {
        case 0...7:
            // 80% text responses
            messageType = .text(textResponses.randomElement() ?? "Got it!")
            
        case 8:
            // 10% image response
            let image = SampleImageGenerator.generate()
            let caption = imageCaptions.randomElement() ?? nil
            messageType = .image(image, caption)
            
        default:
            // 10% video response
            let thumbnail = SampleImageGenerator.generate()
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("sample_\(UUID().uuidString).mov")
            let caption = videoCaptions.randomElement() ?? nil
            messageType = .video(tempURL, thumbnail, caption)
        }
        
        return Message(
            type: messageType,
            isFromCurrentUser: false,
            timestamp: Date()
        )
    }
}

// MARK: - Sample Image Generator
enum SampleImageGenerator {
    private static let colors: [UIColor] = [
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPink,
        .systemPurple,
        .systemTeal,
        .systemIndigo
    ]
    
    static func generate(size: CGSize = CGSize(width: 300, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            colors.randomElement()?.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some visual interest
            UIColor.white.withAlphaComponent(0.3).setFill()
            let circlePath = UIBezierPath(
                ovalIn: CGRect(
                    x: size.width * 0.3,
                    y: size.height * 0.3,
                    width: size.width * 0.4,
                    height: size.height * 0.4
                )
            )
            circlePath.fill()
        }
    }
}

// MARK: - MediaItem Extension
extension MediaItem {
    func toMessageType(caption: String?) -> MessageType {
        switch self {
        case .image(let image, let identifier):
            return .image(image, caption)
            
        case .video(let url, let thumbnail, let identifier):
            return .video(url, thumbnail, caption)
            
        case .pdf(let url, let thumbnail, let name, let identifier):
            return .pdf(url, thumbnail, name)
        }
    }
}

// MARK: - Message Type Extension
extension MessageType {
    var hasMedia: Bool {
        switch self {
        case .text:
            return false
        case .image, .video, .audio, .pdf:
            return true
        }
    }
    
    var caption: String? {
        switch self {
        case .text(let text):
            return text
        case .image(_, let caption), .video(_, _, let caption):
            return caption
        case .audio:
            return nil
        case .pdf(_, _, _):
            return nil
        }
    }
}

