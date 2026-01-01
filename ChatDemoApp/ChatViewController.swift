//
//  ChatViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 30/12/25.
//

import UIKit
import AVKit
import PhotosUI

// MARK: - Chat View Controller
class ChatViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageInputView: UIView!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var mediaPreviewContainer: UIView!
    @IBOutlet weak var mediaPreviewImageView: UIImageView!
    @IBOutlet weak var removeMediaButton: UIButton!
    @IBOutlet weak var playIconImageView: UIImageView!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    private var messages: [Message] = []
    var user: User!
    
    // Pending media to send
    private var pendingImage: UIImage?
    private var pendingVideoURL: URL?
    private var pendingVideoThumbnail: UIImage?
    
    // TextView properties
    private let textViewMinHeight: CGFloat = 36
    private let textViewMaxHeight: CGFloat = 150
    private var placeholderLabel: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupKeyboardObservers()
        loadSampleMessages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure TextView (replacing TextField)
        setupTextView()
        
        // Configure buttons
        sendButton.isEnabled = false
        
        removeMediaButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeMediaButton.tintColor = .systemGray
        removeMediaButton.backgroundColor = .white
        removeMediaButton.layer.cornerRadius = 12
        
        // Configure media preview
        mediaPreviewContainer.backgroundColor = .systemGray6
        mediaPreviewContainer.layer.cornerRadius = 8
        mediaPreviewContainer.isHidden = true
        
        mediaPreviewImageView.contentMode = .scaleAspectFill
        mediaPreviewImageView.clipsToBounds = true
        mediaPreviewImageView.layer.cornerRadius = 6
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        playIconImageView.image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        playIconImageView.tintColor = .white
        playIconImageView.isHidden = true
        
        // Add border to input view
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.5)
        topBorder.backgroundColor = UIColor.separator.cgColor
        messageInputView.layer.addSublayer(topBorder)
        
        // Add a test button to simulate receiving media (for demo purposes)
        let testButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showTestMenu))
        testButton.accessibilityLabel = "Menu"
        
        navigationItem.rightBarButtonItem = testButton
        setupCustomLeftBarButton()
        setupNavigationBarButtons()
    }
    private func setupNavigationBarButtons() {
        // Create video call button
        let videoCallButton = UIButton(type: .system)
        videoCallButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        videoCallButton.tintColor = .black
        videoCallButton.addTarget(self, action: #selector(videoCallTapped), for: .touchUpInside)
        videoCallButton.translatesAutoresizingMaskIntoConstraints = false
        videoCallButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        videoCallButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // Create audio call button
        let audioCallButton = UIButton(type: .system)
        audioCallButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        audioCallButton.tintColor = .black
        audioCallButton.addTarget(self, action: #selector(audioCallTapped), for: .touchUpInside)
        audioCallButton.translatesAutoresizingMaskIntoConstraints = false
        audioCallButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        audioCallButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // Create menu button (existing test button)
        let menuButton = UIButton(type: .system)
        menuButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        menuButton.tintColor = .black
        menuButton.addTarget(self, action: #selector(showTestMenu), for: .touchUpInside)
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        menuButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // Create bar button items
        let videoBarButton = UIBarButtonItem(customView: videoCallButton)
        let audioBarButton = UIBarButtonItem(customView: audioCallButton)
        let menuBarButton = UIBarButtonItem(customView: menuButton)
        
        // Add to navigation bar
        navigationItem.rightBarButtonItems = [menuBarButton, videoBarButton, audioBarButton]
    }

    // MARK: - Call Actions
    @objc private func audioCallTapped() {
        let alert = UIAlertController(
            title: "Audio Call",
            message: "Start an audio call with \(user.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Call", style: .default) { [weak self] _ in
            self?.initiateAudioCall()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    @objc private func videoCallTapped() {
        let alert = UIAlertController(
            title: "Video Call",
            message: "Start a video call with \(user.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Call", style: .default) { [weak self] _ in
            self?.initiateVideoCall()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    private func initiateAudioCall() {
        // Implement your audio call logic here
        print("Initiating audio call with \(user.name)")
        
        // Example: Show a simple alert for demo
        let alert = UIAlertController(
            title: "Audio Call",
            message: "Audio call feature will be implemented here",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func initiateVideoCall() {
        // Implement your video call logic here
        print("Initiating video call with \(user.name)")
        
        // Example: Show a simple alert for demo
        let alert = UIAlertController(
            title: "Video Call",
            message: "Video call feature will be implemented here",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupTextView() {
        messageTextView.delegate = self
        messageTextView.font = .systemFont(ofSize: 16)
        messageTextView.layer.cornerRadius = 18
        messageTextView.layer.borderWidth = 0.5
        messageTextView.layer.borderColor = UIColor.separator.cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageTextView.isScrollEnabled = false
        messageTextView.backgroundColor = .systemBackground
        
        // Add placeholder label
        placeholderLabel = UILabel()
        placeholderLabel.text = "Type a message..."
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 13),
            placeholderLabel.topAnchor.constraint(equalTo: messageTextView.topAnchor, constant: 8)
        ])
        
        // Set initial height constraint
        messageTextViewHeightConstraint.constant = textViewMinHeight
    }
    
    private func setupCustomLeftBarButton() {
        // Create custom back button
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("", for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Container view for avatar and name
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar ImageView
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .systemGray4
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let avatar = user.avatarImage {
            avatarImageView.image = avatar
        } else {
            avatarImageView.image = createInitialsImage(from: user.name, size: 36)
        }
        
        // Name Label
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to container
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
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Add tap gesture to user info
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userInfoTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        // Create bar button items
        let backBarButton = UIBarButtonItem(customView: backButton)
        let userInfoBarButton = UIBarButtonItem(customView: containerView)
        
        // Add both to navigation bar
        navigationItem.leftBarButtonItems = [backBarButton, userInfoBarButton]
        navigationItem.hidesBackButton = true
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func userInfoTapped() {
        // You can add action here, like showing user profile
        print("User info tapped - show user profile")
    }
    
    private func setupTableView() {
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
    }
    
    private func setupKeyboardObservers() {
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
    
    private func loadSampleMessages() {
        // Generate sample image for demo
        let sampleImage = generateSampleImage()
        
        messages = [
            Message(type: .text("Hey! How are you?"), isFromCurrentUser: false, timestamp: Date().addingTimeInterval(-3600)),
            Message(type: .text("I'm doing great, thanks! How about you?"), isFromCurrentUser: true, timestamp: Date().addingTimeInterval(-3500)),
            Message(type: .image(sampleImage, "Check out this photo!"), isFromCurrentUser: false, timestamp: Date().addingTimeInterval(-3400)),
            Message(type: .text("That's amazing! 😍"), isFromCurrentUser: true, timestamp: Date().addingTimeInterval(-3300)),
            Message(type: .text("Pretty good! Just working on a new project."), isFromCurrentUser: false, timestamp: Date().addingTimeInterval(-3200)),
            Message(type: .text("That sounds exciting! What kind of project?"), isFromCurrentUser: true, timestamp: Date().addingTimeInterval(-3100))
        ]
        chatTableView.reloadData()
        scrollToBottom(animated: false)
    }
    
    // MARK: - TextView Height Management
    private func adjustTextViewHeight() {
        let size = messageTextView.sizeThatFits(CGSize(width: messageTextView.frame.width, height: .infinity))
        var newHeight = size.height
        
        // Clamp between min and max
        newHeight = max(textViewMinHeight, min(newHeight, textViewMaxHeight))
        
        // Enable scrolling only when max height is reached
        messageTextView.isScrollEnabled = newHeight >= textViewMaxHeight
        
        // Update constraint if height changed
        if messageTextViewHeightConstraint.constant != newHeight {
            messageTextViewHeightConstraint.constant = newHeight
            
            // Adjust input view height accordingly
            let baseHeight: CGFloat = 60
            let extraHeight = newHeight - textViewMinHeight
            inputViewHeightConstraint.constant = baseHeight + extraHeight
            
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        messageTextView.endEditing(true)
        
        let alert = UIAlertController(title: "Add Media", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        })
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = attachmentButton
            popover.sourceRect = attachmentButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        let text = messageTextView.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let caption = text.isEmpty ? nil : text
        
        // Determine message type
        let messageType: MessageType
        
        if let image = pendingImage {
            messageType = .image(image, caption)
        } else if let videoURL = pendingVideoURL {
            messageType = .video(videoURL, pendingVideoThumbnail, caption)
        } else if !text.isEmpty {
            messageType = .text(text)
        } else {
            return
        }
        
        // Create and send message
        let newMessage = Message(type: messageType, isFromCurrentUser: true, timestamp: Date())
        messages.append(newMessage)
        
        // Clear input
        messageTextView.text = ""
        placeholderLabel.isHidden = false
        clearPendingMedia()
        sendButton.isEnabled = false
        
        // Reset text view height
        messageTextViewHeightConstraint.constant = textViewMinHeight
        messageTextView.isScrollEnabled = false
        inputViewHeightConstraint.constant = 60
        
        chatTableView.reloadData()
        scrollToBottom(animated: true)
        
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.simulateResponse()
        }
    }
    
    @IBAction func removeMediaTapped(_ sender: UIButton) {
        clearPendingMedia()
        updateSendButtonState()
    }
    
    // MARK: - Actions
    @objc private func showTestMenu() {
        let alert = UIAlertController(title: "Test Options", message: "Simulate receiving media", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Receive Image", style: .default) { [weak self] _ in
            self?.simulateReceivedImage()
        })
        
        alert.addAction(UIAlertAction(title: "Receive Image with Caption", style: .default) { [weak self] _ in
            self?.simulateReceivedImageWithCaption()
        })
        
        alert.addAction(UIAlertAction(title: "Receive Video", style: .default) { [weak self] _ in
            self?.simulateReceivedVideo()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func simulateReceivedImage() {
        let image = generateSampleImage()
        let message = Message(type: .image(image, nil), isFromCurrentUser: false, timestamp: Date())
        messages.append(message)
        chatTableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    private func simulateReceivedImageWithCaption() {
        let image = generateSampleImage()
        let captions = ["Look at this!", "Amazing view!", "What do you think?", "Just captured this!"]
        let message = Message(type: .image(image, captions.randomElement()), isFromCurrentUser: false, timestamp: Date())
        messages.append(message)
        chatTableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    private func simulateReceivedVideo() {
        let thumbnail = generateSampleImage()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sample_\(UUID().uuidString).mov")
        let captions = ["Check out this video!", "Cool, right?", nil]
        let message = Message(type: .video(tempURL, thumbnail, captions.randomElement() ?? nil), isFromCurrentUser: false, timestamp: Date())
        messages.append(message)
        chatTableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    private func presentImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: "Camera is not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func clearPendingMedia() {
        pendingImage = nil
        pendingVideoURL = nil
        pendingVideoThumbnail = nil
        mediaPreviewImageView.image = nil
        mediaPreviewContainer.isHidden = true
        playIconImageView.isHidden = true
        
        attachmentButton.isHidden = false
        
        // Adjust input view height (accounting for current text view height)
        let baseHeight: CGFloat = 60
        let extraHeight = messageTextViewHeightConstraint.constant - textViewMinHeight
        inputViewHeightConstraint.constant = baseHeight + extraHeight
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showMediaPreview(image: UIImage, isVideo: Bool = false) {
        mediaPreviewImageView.image = image
        mediaPreviewContainer.isHidden = false
        playIconImageView.isHidden = !isVideo
        
        attachmentButton.isHidden = true
        
        // Adjust input view height (accounting for current text view height)
        let baseHeight: CGFloat = 76
        let extraHeight = messageTextViewHeightConstraint.constant - textViewMinHeight
        inputViewHeightConstraint.constant = baseHeight + extraHeight
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        
        updateSendButtonState()
    }
    
    private func updateSendButtonState() {
        let hasText = !(messageTextView.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let hasMedia = pendingImage != nil || pendingVideoURL != nil
        sendButton.isEnabled = hasText || hasMedia
    }
    
    private func simulateResponse() {
        // Randomly decide response type
        let responseType = Int.random(in: 0...10)
        
        let responseMessage: Message
        
        if responseType <= 7 {
            // 70% text responses
            let responses = [
                "That's interesting!",
                "Tell me more about that.",
                "I see what you mean.",
                "Thanks for sharing!"
            ]
            let randomResponse = responses.randomElement() ?? "Got it!"
            responseMessage = Message(type: .text(randomResponse), isFromCurrentUser: false, timestamp: Date())
        } else if responseType == 8 {
            // 10% image response
            let image = generateSampleImage()
            let captions = ["Check this out!", "Look at this!", nil, "Amazing, right?"]
            responseMessage = Message(type: .image(image, captions.randomElement() ?? nil), isFromCurrentUser: false, timestamp: Date())
        } else {
            // 20% video response simulation (using image with play button)
            let thumbnail = generateSampleImage()
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sample.mov")
            let captions = ["Watch this!", "Cool video!", nil]
            responseMessage = Message(type: .video(tempURL, thumbnail, captions.randomElement() ?? nil), isFromCurrentUser: false, timestamp: Date())
        }
        
        messages.append(responseMessage)
        
        chatTableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    private func generateSampleImage() -> UIImage {
        // Generate a random colored image for demo
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemPurple, .systemOrange, .systemPink]
        let color = colors.randomElement() ?? .systemBlue
        
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some text to make it interesting
            let text = "📷"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 100),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func createInitialsImage(from name: String, size: CGFloat = 32) -> UIImage? {
        let initials = name.components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let imageSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            
            // Draw circle
            let rect = CGRect(origin: .zero, size: imageSize)
            UIBezierPath(ovalIn: rect).fill()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let fontSize = size * 0.4
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(x: (imageSize.width - textSize.width) / 2,
                                  y: (imageSize.height - textSize.height) / 2,
                                  width: textSize.width,
                                  height: textSize.height)
            
            initials.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Keyboard Handlers
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        // Since the constraint is to safe area, we need to account for that
        let keyboardHeight = keyboardFrame.height
        inputViewBottomConstraint.constant += keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        
        scrollToBottom(animated: true)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        inputViewBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        let message = messages[indexPath.row]
        cell.configure(with: message)
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate
extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder visibility
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Adjust height
        adjustTextViewHeight()
        
        // Update send button state
        updateSendButtonState()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle return key (send message)
        if text == "\n" {
            if sendButton.isEnabled {
                sendButtonTapped(sendButton)
            }
            return false
        }
        return true
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                guard let url = url, error == nil else { return }
                
                // Copy to temp directory
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
                try? FileManager.default.copyItem(at: url, to: tempURL)
                
                // Generate thumbnail
                let asset = AVAsset(url: tempURL)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                var thumbnail: UIImage?
                if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
                    thumbnail = UIImage(cgImage: cgImage)
                }
                
                DispatchQueue.main.async {
                    self?.pendingVideoURL = tempURL
                    self?.pendingVideoThumbnail = thumbnail
                    if let thumb = thumbnail {
                        self?.showMediaPreview(image: thumb, isVideo: true)
                    }
                }
            }
        } else if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let image = image as? UIImage, error == nil else { return }
                
                DispatchQueue.main.async {
                    self?.pendingImage = image
                    self?.showMediaPreview(image: image, isVideo: false)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let videoURL = info[.mediaURL] as? URL {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            var thumbnail: UIImage?
            if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
                thumbnail = UIImage(cgImage: cgImage)
            }
            
            pendingVideoURL = videoURL
            pendingVideoThumbnail = thumbnail
            if let thumb = thumbnail {
                showMediaPreview(image: thumb, isVideo: true)
            }
        } else if let image = info[.originalImage] as? UIImage {
            pendingImage = image
            showMediaPreview(image: image, isVideo: false)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - ChatMessageCellDelegate
extension ChatViewController: ChatMessageCellDelegate {
    func didTapImage(_ image: UIImage) {
        let vc = FullScreenImageViewController(image: image)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func didTapVideo(_ videoURL: URL) {
        let player = AVPlayer(url: videoURL)
        let vc = AVPlayerViewController()
        vc.player = player
        present(vc, animated: true) {
            player.play()
        }
    }
}
