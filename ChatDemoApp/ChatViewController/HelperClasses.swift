//
//  HelperClasses.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit
import AVKit
import PDFKit
import UniformTypeIdentifiers

// MARK: - Text View Configuration
struct TextViewConfiguration {
    let minHeight: CGFloat = 36
    let maxHeight: CGFloat = 150
    let cornerRadius: CGFloat = 18
    let borderWidth: CGFloat = 0.5
    let textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    let placeholderInsets = UIEdgeInsets(top: 8, left: 13, bottom: 0, right: 0)
}

// MARK: - Input Manager
final class InputManager {
    
    func configure(
        messageTextView: UITextView,
        placeholderLabel: UILabel,
        sendButton: UIButton,
        voiceRecordButton: UIButton,
        configuration: TextViewConfiguration
    ) {
        // Configure text view
        messageTextView.font = .systemFont(ofSize: 16)
        messageTextView.layer.cornerRadius = configuration.cornerRadius
        messageTextView.layer.borderWidth = configuration.borderWidth
        messageTextView.layer.borderColor = UIColor.separator.cgColor
        messageTextView.textContainerInset = configuration.textInsets
        messageTextView.isScrollEnabled = false
        messageTextView.backgroundColor = .systemBackground
        
        // Configure placeholder
        placeholderLabel.text = "Type a message..."
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(
                equalTo: messageTextView.leadingAnchor,
                constant: configuration.placeholderInsets.left
            ),
            placeholderLabel.topAnchor.constraint(
                equalTo: messageTextView.topAnchor,
                constant: configuration.placeholderInsets.top
            )
        ])
        
        // Configure buttons
        sendButton.isEnabled = false
        sendButton.isHidden = true
        voiceRecordButton.isHidden = false
    }
    
    func handleTextChange(
        textView: UITextView,
        heightConstraint: NSLayoutConstraint,
        inputViewHeightConstraint: NSLayoutConstraint,
        configuration: TextViewConfiguration,
        hasMedia: Bool,
        animateLayout: @escaping () -> Void
    ) {
        // Update placeholder
        textView.superview?.subviews
            .compactMap { $0 as? UILabel }
            .first?
            .isHidden = !textView.text.isEmpty
        
        // Calculate and adjust height
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        var newHeight = max(configuration.minHeight, min(size.height, configuration.maxHeight))
        
        textView.isScrollEnabled = newHeight >= configuration.maxHeight
        
        if heightConstraint.constant != newHeight {
            heightConstraint.constant = newHeight
            
            let baseHeight: CGFloat = hasMedia ? 176 : 60
            let extraHeight = newHeight - configuration.minHeight
            inputViewHeightConstraint.constant = baseHeight + extraHeight
            
            UIView.animate(withDuration: 0.2) {
                animateLayout()
            }
        }
        
        // Update send button
        let hasText = !textView.text.trimmingCharacters(in: .whitespaces).isEmpty
        updateSendButtonState(hasText: hasText, hasMedia: hasMedia)
    }
    
    func updateSendButtonState(hasText: Bool, hasMedia: Bool) {
        // This will be called from the view controller to access buttons
    }
    
    func resetInput(
        textView: UITextView,
        heightConstraint: NSLayoutConstraint,
        inputViewHeightConstraint: NSLayoutConstraint,
        configuration: TextViewConfiguration
    ) {
        textView.text = ""
        textView.superview?.subviews
            .compactMap { $0 as? UILabel }
            .first?
            .isHidden = false
        
        heightConstraint.constant = configuration.minHeight
        textView.isScrollEnabled = false
        inputViewHeightConstraint.constant = 60
    }
}

// MARK: - Keyboard Manager
protocol KeyboardManagerDelegate: AnyObject {
    func keyboardWillShow(height: CGFloat, duration: TimeInterval)
    func keyboardWillHide(duration: TimeInterval)
}

final class KeyboardManager {
    weak var delegate: KeyboardManagerDelegate?
    
    func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        delegate?.keyboardWillShow(height: keyboardFrame.height, duration: duration)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        delegate?.keyboardWillHide(duration: duration)
    }
}

// MARK: - Voice Recording Manager
protocol VoiceRecordingDelegate: AnyObject {
    func didFinishRecording(url: URL, duration: TimeInterval)
    func didCancelRecording()
    func didFailRecording(error: Error)
}

final class VoiceRecordingManager: NSObject {
    weak var delegate: VoiceRecordingDelegate?
    
    private weak var recordButton: UIButton?
    private weak var overlay: RecordingOverlayView?
    private weak var textView: UITextView?
    private weak var attachmentButton: UIButton?
    
    private var isRecordingCancelled = false
    
    func configure(
        button: UIButton,
        overlay: RecordingOverlayView,
        container: UIView,
        textView: UITextView,
        delegate: VoiceRecordingDelegate
    ) {
        self.recordButton = button
        self.overlay = overlay
        self.textView = textView
        self.delegate = delegate
        
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 22
        button.clipsToBounds = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        button.addGestureRecognizer(longPress)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        button.addGestureRecognizer(pan)
        
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isHidden = true
        container.addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            overlay.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
            overlay.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            overlay.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        AudioRecordingManager.shared.onRecordingUpdate = { [weak overlay] duration in
            overlay?.updateTime(duration)
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startRecording()
        case .ended, .cancelled, .failed:
            if isRecordingCancelled {
                cancelRecording()
            } else {
                finishRecording()
            }
            isRecordingCancelled = false
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let button = recordButton else { return }
        
        let translation = gesture.translation(in: button)
        let progress = min(1.0, max(0.0, -translation.x / 150.0))
        
        overlay?.updateCancelProgress(progress)
        
        if progress >= 1.0 {
            isRecordingCancelled = true
            gesture.isEnabled = false
            gesture.isEnabled = true
        }
    }
    
    private func startRecording() {
        do {
            _ = try AudioRecordingManager.shared.startRecording()
            showRecordingUI()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            delegate?.didFailRecording(error: error)
        }
    }
    
    private func cancelRecording() {
        AudioRecordingManager.shared.cancelRecording()
        hideRecordingUI()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        delegate?.didCancelRecording()
    }
    
    private func finishRecording() {
        guard let result = AudioRecordingManager.shared.stopRecording(),
              let url = result.0 else {
            cancelRecording()
            return
        }
        
        let duration = result.1
        
        guard duration >= 1.0 else {
            try? FileManager.default.removeItem(at: url)
            cancelRecording()
            return
        }
        
        hideRecordingUI()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        delegate?.didFinishRecording(url: url, duration: duration)
    }
    
    private func showRecordingUI() {
        textView?.resignFirstResponder()
        
        UIView.animate(withDuration: 0.2) {
            self.overlay?.isHidden = false
            self.textView?.alpha = 0
            self.attachmentButton?.alpha = 0
        }
    }
    
    private func hideRecordingUI() {
        UIView.animate(withDuration: 0.2) {
            self.overlay?.isHidden = true
            self.textView?.alpha = 1
            self.attachmentButton?.alpha = 1
        }
    }
}

// MARK: - Navigation Bar Configurator
final class NavigationBarConfigurator {
    
    func configure(navigationItem: UINavigationItem,user: User,target: Any,
        backAction: Selector,
        userInfoAction: Selector,
        audioCallAction: Selector,
        videoCallAction: Selector,
        menuAction: Selector) {
        
        configureLeftBarButtons(navigationItem: navigationItem,user: user,target: target,
            backAction: backAction,
            userInfoAction: userInfoAction)
        
        configureRightBarButtons(
            navigationItem: navigationItem,target: target,audioCallAction: audioCallAction,videoCallAction: videoCallAction,menuAction: menuAction)
        
        navigationItem.hidesBackButton = true
    }
    
    private func configureLeftBarButtons(
        navigationItem: UINavigationItem,
        user: User,
        target: Any,
        backAction: Selector,
        userInfoAction: Selector
    ) {
        let backButton = createButton(
            systemImage: "chevron.left",
            target: target,
            action: backAction
        )
        
        let containerView = createUserInfoView(user: user, target: target, action: userInfoAction)
        
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(customView: backButton),
            UIBarButtonItem(customView: containerView)
        ]
    }
    
    private func configureRightBarButtons(
        navigationItem: UINavigationItem,
        target: Any,
        audioCallAction: Selector,
        videoCallAction: Selector,
        menuAction: Selector
    ) {
        let videoButton = createButton(systemImage: "video.fill", target: target, action: videoCallAction)
        let audioButton = createButton(systemImage: "phone.fill", target: target, action: audioCallAction)
        let menuButton = createButton(systemImage: "ellipsis.circle", target: target, action: menuAction)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: menuButton),
            UIBarButtonItem(customView: videoButton),
            UIBarButtonItem(customView: audioButton)
        ]
    }
    
    private func createButton(systemImage: String, target: Any, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.tintColor = .black
        button.addTarget(target, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return button
    }
    
    private func createUserInfoView(user: User, target: Any, action: Selector) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .systemGray4
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = user.avatarImage ?? UserAvatarGenerator.createInitialsImage(from: user.name)
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            containerView.heightAnchor.constraint(equalToConstant: 36),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        return containerView
    }
}

// MARK: - User Avatar Generator
enum UserAvatarGenerator {
    static func createInitialsImage(from name: String, size: CGFloat = 36) -> UIImage? {
        let initials = name.components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let imageSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: imageSize)).fill()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let fontSize = size * 0.4
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (imageSize.width - textSize.width) / 2,
                y: (imageSize.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            initials.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - Document Processor
enum DocumentProcessor {
    static func processDocuments(_ urls: [URL]) -> [MediaItem] {
        var mediaItems: [MediaItem] = []
        
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Could not access security-scoped resource for: \(url.lastPathComponent)")
                continue
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Copy to app's DOCUMENTS directory (not temporary)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            do {
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                let fileName = url.lastPathComponent
                let thumbnail = generatePDFThumbnail(url: destinationURL)
                
                let item = MediaItem.pdf(destinationURL, thumbnail: thumbnail, name: fileName)
                mediaItems.append(item)
                
                print("✅ Successfully copied PDF to: \(destinationURL.path)")
                
            } catch {
                print("❌ Error copying file: \(error.localizedDescription)")
            }
        }
        
        return mediaItems
    }
    private static func generatePDFThumbnail(url: URL) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else {
            print("❌ Could not generate PDF thumbnail")
            return nil
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        
        // Scale down for thumbnail
        let thumbnailSize = CGSize(
            width: min(pageRect.width, 200),
            height: min(pageRect.height, 200)
        )
        
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: thumbnailSize))
            
            ctx.cgContext.translateBy(x: 0.0, y: thumbnailSize.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // Scale to fit thumbnail
            let scale = min(
                thumbnailSize.width / pageRect.width,
                thumbnailSize.height / pageRect.height
            )
            ctx.cgContext.scaleBy(x: scale, y: scale)
            
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}

// MARK: - Media Item Presenter
enum MediaItemPresenter {
    static func present(item: MediaItem, from viewController: UIViewController) {
        switch item {
        case .image(let image, _):
            let vc = FullScreenImageViewController(image: image)
            vc.modalPresentationStyle = .fullScreen
            viewController.present(vc, animated: true)
            
        case .video(let url, _, _):
            let player = AVPlayer(url: url)
            let vc = AVPlayerViewController()
            vc.player = player
            viewController.present(vc, animated: true) {
                player.play()
            }
            
        case .pdf(let url, _, let name, _):
            let pdfVC = PDFViewerViewController(pdfURL: url, fileName: name)
            pdfVC.modalPresentationStyle = .fullScreen
            viewController.present(pdfVC, animated: true)
        }
    }
}

// MARK: - Attachment Menu Presenter
enum AttachmentMenuPresenter {
    
    static func present(from viewController: UIViewController, sourceView: UIView) {
        let alert = UIAlertController(title: "Add Media", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photos & Videos", style: .default) { _ in
            presentMediaPicker(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Document", style: .default) { _ in
            presentDocumentPicker(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            presentCamera(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        viewController.present(alert, animated: true)
    }
    
    private static func presentMediaPicker(from viewController: UIViewController) {
        let picker = MultiMediaPickerViewController()
        picker.delegate = viewController as? MultiMediaPickerDelegate
        picker.modalPresentationStyle = .fullScreen
        viewController.present(picker, animated: true)
    }
    
    private static func presentDocumentPicker(from viewController: UIViewController) {
        print("\n📱 Creating document picker with asCopy: true")
        
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.pdf],
            asCopy: true
        )
        
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.allowsMultipleSelection = false
        
        print("✅ Document picker configured correctly\n")
        
        viewController.present(documentPicker, animated: true)
    }
    
    private static func presentCamera(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(from: viewController, message: "Camera is not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.delegate = viewController as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        viewController.present(picker, animated: true)
    }
    
    private static func showAlert(from viewController: UIViewController, message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}

// MARK: - Test Menu Presenter
enum TestMenuPresenter {
    static func present(from viewController: UIViewController, viewModel: ChatViewModelProtocol) {
        let alert = UIAlertController(title: "Test Options", message: "Simulate receiving media", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Receive Image", style: .default) { _ in
            simulateReceivedImage(viewModel: viewModel)
        })
        
        alert.addAction(UIAlertAction(title: "Receive Image with Caption", style: .default) { _ in
            simulateReceivedImageWithCaption(viewModel: viewModel)
        })
        
        alert.addAction(UIAlertAction(title: "Receive Video", style: .default) { _ in
            simulateReceivedVideo(viewModel: viewModel)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = viewController.navigationItem.rightBarButtonItem
        }
        
        viewController.present(alert, animated: true)
    }
    
    private static func simulateReceivedImage(viewModel: ChatViewModelProtocol) {
        // Implementation would use viewModel to add message
    }
    
    private static func simulateReceivedImageWithCaption(viewModel: ChatViewModelProtocol) {
        // Implementation would use viewModel to add message
    }
    
    private static func simulateReceivedVideo(viewModel: ChatViewModelProtocol) {
        // Implementation would use viewModel to add message
    }
}
