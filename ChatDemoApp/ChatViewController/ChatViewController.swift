//
//  ChatViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 30/12/25.
//

import UIKit
import AVKit
import PhotosUI
import PDFKit

// MARK: - ChatViewController
final class ChatViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var chatTableView: UITableView!
    @IBOutlet private weak var messageInputView: UIView!
    @IBOutlet private weak var attachmentButton: UIButton!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var inputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var voiceRecordButton: UIButton!
    
    // MARK: - Properties
    var user: User!
    private let viewModel: ChatViewModelProtocol
    
    private lazy var mediaPreviewContainer = MediaPreviewContainerView()
    private lazy var recordingOverlay = RecordingOverlayView(frame: .zero)
    private lazy var placeholderLabel = UILabel()
    
    private let textViewConfig = TextViewConfiguration()
    private let inputManager: InputManager
    private let keyboardManager: KeyboardManager
    private let voiceRecordingManager: VoiceRecordingManager
    private let navigationBarConfigurator: NavigationBarConfigurator
    
    // MARK: - Init
    init(user: User, viewModel: ChatViewModelProtocol = ChatViewModel()) {
        self.user = user
        self.viewModel = viewModel
        self.inputManager = InputManager()
        self.keyboardManager = KeyboardManager()
        self.voiceRecordingManager = VoiceRecordingManager()
        self.navigationBarConfigurator = NavigationBarConfigurator()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ChatViewModel()
        self.inputManager = InputManager()
        self.keyboardManager = KeyboardManager()
        self.voiceRecordingManager = VoiceRecordingManager()
        self.navigationBarConfigurator = NavigationBarConfigurator()
        
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewModel()
    }
    
    deinit {
        keyboardManager.removeObservers()
    }
    
    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        setupInputArea()
        setupMediaPreview()
        setupVoiceRecording()
        setupKeyboard()
    }
    
    private func setupNavigationBar() {
        navigationBarConfigurator.configure(
            navigationItem: navigationItem,
            user: user,
            target: self,
            backAction: #selector(backButtonTapped),
            userInfoAction: #selector(userInfoTapped),
            audioCallAction: #selector(audioCallTapped),
            videoCallAction: #selector(videoCallTapped),
            menuAction: #selector(showTestMenu)
        )
    }
    
    private func setupTableView() {
        chatTableView.delegate = self
        chatTableView.dataSource = self
//        let nib = UINib(nibName: "ChatMessageCell", bundle: nil)
//        chatTableView.register(nib, forCellReuseIdentifier: "ChatMessageCell")
        chatTableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        chatTableView.separatorStyle = .none
        chatTableView.keyboardDismissMode = .interactive
    }
    
    private func setupInputArea() {
        inputManager.configure(
            messageTextView: messageTextView,
            placeholderLabel: placeholderLabel,
            sendButton: sendButton,
            voiceRecordButton: voiceRecordButton,
            configuration: textViewConfig
        )
        
        messageTextView.delegate = self
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.5)
        topBorder.backgroundColor = UIColor.separator.cgColor
        messageInputView.layer.addSublayer(topBorder)
    }
    
    private func setupMediaPreview() {
        mediaPreviewContainer.translatesAutoresizingMaskIntoConstraints = false
        mediaPreviewContainer.isHidden = true
        messageInputView.insertSubview(mediaPreviewContainer, at: 0)
        
        NSLayoutConstraint.activate([
            mediaPreviewContainer.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 12),
            mediaPreviewContainer.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -12),
            mediaPreviewContainer.bottomAnchor.constraint(equalTo: messageTextView.topAnchor, constant: -8),
            mediaPreviewContainer.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        mediaPreviewContainer.onRemoveItem = { [weak self] id in
            self?.handleRemoveMedia(id: id)
        }
        
        mediaPreviewContainer.onTapItem = { [weak self] item in
            self?.handleMediaItemTap(item)
        }
    }
    
    private func setupVoiceRecording() {
        voiceRecordingManager.configure(
            button: voiceRecordButton,
            overlay: recordingOverlay,
            container: messageInputView,
            textView: messageTextView,
            delegate: self
        )
    }
    
    private func setupKeyboard() {
        keyboardManager.delegate = self
        keyboardManager.setupObservers()
    }
    
    private func bindViewModel() {
        viewModel.onMessagesUpdated = { [weak self] in
            self?.handleMessagesUpdate()
        }
        
        viewModel.onPendingMediaUpdated = { [weak self] in
            self?.handlePendingMediaUpdate()
        }
    }
    
    // MARK: - ViewModel Handlers
    private func handleMessagesUpdate() {
        chatTableView.reloadData()
        scrollToBottom(animated: true)
    }
    
    private func handlePendingMediaUpdate() {
        mediaPreviewContainer.mediaItems = viewModel.pendingMediaItems
        inputManager.updateSendButtonState(
            hasText: !messageTextView.text.trimmingCharacters(in: .whitespaces).isEmpty,
            hasMedia: !viewModel.pendingMediaItems.isEmpty
        )
        
        if viewModel.pendingMediaItems.isEmpty {
            hideMediaPreview()
        } else {
            showMediaPreview()
        }
    }
    
    // MARK: - Actions
    @IBAction private func attachmentButtonTapped(_ sender: UIButton) {
        messageTextView.endEditing(true)
        AttachmentMenuPresenter.present(from: self, sourceView: sender)
    }
    
    @IBAction private func sendButtonTapped(_ sender: UIButton) {
        let text = messageTextView.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        if viewModel.pendingMediaItems.isEmpty {
            viewModel.sendText(text)
        } else {
            viewModel.sendPendingMedia(caption: text.isEmpty ? nil : text)
        }
        
        inputManager.resetInput(
            textView: messageTextView,
            heightConstraint: messageTextViewHeightConstraint,
            inputViewHeightConstraint: inputViewHeightConstraint,
            configuration: textViewConfig
        )
        
        view.layoutIfNeeded()
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func userInfoTapped() {
        // Navigate to user profile
        print("User info tapped - show user profile")
    }
    
    @objc private func audioCallTapped() {
        // TODO: Implement audio call functionality
    }
    
    @objc private func videoCallTapped() {
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Starting video call...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: loadingAlert.view.topAnchor, constant: 65)
        ])
        
        present(loadingAlert, animated: true)
        
        // Generate room name and fetch token
        let roomName = "room_\(user.id)_\(UUID().uuidString.prefix(8))"
        let currentUserName = "\(user.name)" // Replace with actual current user name
        
        TokenService.shared.fetchToken(identity: currentUserName, roomName: roomName) { [weak self] result in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let token):
                        let videoVC = VideoCallViewController(
                            token: token,
                            roomName: roomName,
                            callerName: self.user.name
                        )
                        videoVC.modalPresentationStyle = .fullScreen
                        self.present(videoVC, animated: true)
                        
                    case .failure(let error):
                        let alert = UIAlertController(
                            title: "Failed to Start Call",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func showTestMenu() {
        TestMenuPresenter.present(from: self, viewModel: viewModel)
    }
    
    // MARK: - Media Handling
    private func handleRemoveMedia(id: String) {
        viewModel.removePendingMedia(id: id)
    }
    
    private func handleMediaItemTap(_ item: MediaItem) {
        MediaItemPresenter.present(item: item, from: self)
    }
    
    private func showMediaPreview() {
        mediaPreviewContainer.isHidden = false
        attachmentButton.isHidden = true
        
        let baseHeight: CGFloat = 176
        let extraHeight = messageTextViewHeightConstraint.constant - textViewConfig.minHeight
        inputViewHeightConstraint.constant = baseHeight + extraHeight
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideMediaPreview() {
        mediaPreviewContainer.isHidden = true
        mediaPreviewContainer.clearAll()
        attachmentButton.isHidden = false
        
        let baseHeight: CGFloat = 60
        let extraHeight = messageTextViewHeightConstraint.constant - textViewConfig.minHeight
        inputViewHeightConstraint.constant = baseHeight + extraHeight
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helpers
    private func scrollToBottom(animated: Bool) {
        guard viewModel.messages.count > 0 else { return }
        let indexPath = IndexPath(row: viewModel.messages.count - 1, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        cell.configure(with: viewModel.messages[indexPath.row])
        //cell.delegate = self
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
        inputManager.handleTextChange(
            textView: textView,
            heightConstraint: messageTextViewHeightConstraint,
            inputViewHeightConstraint: inputViewHeightConstraint,
            configuration: textViewConfig,
            hasMedia: !viewModel.pendingMediaItems.isEmpty,
            animateLayout: { [weak self] in
                self?.view.layoutIfNeeded()
            }
        )
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if sendButton.isEnabled {
                sendButtonTapped(sendButton)
            }
            return false
        }
        return true
    }
}

// MARK: - ChatMessageCellDelegate
//extension ChatViewController: ChatMessageCellDelegate {
//    func didTapImage(_ image: UIImage) {
//        let vc = FullScreenImageViewController(image: image)
//        vc.modalPresentationStyle = .fullScreen
//        present(vc, animated: true)
//    }
//    
//    func didTapVideo(_ videoURL: URL) {
//        let player = AVPlayer(url: videoURL)
//        let vc = AVPlayerViewController()
//        vc.player = player
//        present(vc, animated: true) {
//            player.play()
//        }
//    }
//    
//    func didTapPDF(_ pdfURL: URL, fileName: String) {
//        let pdfVC = PDFViewerViewController(pdfURL: pdfURL, fileName: fileName)
//        pdfVC.modalPresentationStyle = .fullScreen
//        present(pdfVC, animated: true)
//    }
//}

// MARK: - MultiMediaPickerDelegate
extension ChatViewController: MultiMediaPickerDelegate {
    func didSelectMedia(_ items: [MediaItem]) {
        viewModel.addPendingMedia(items)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ChatViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📄 DOCUMENT PICKER DELEGATE CALLED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Number of files: \(urls.count)")
        
        for (index, url) in urls.enumerated() {
            print("\n🔍 FILE #\(index + 1) DIAGNOSTICS:")
            print("   📝 Filename: \(url.lastPathComponent)")
            print("   📍 Path: \(url.path)")
            print("   ✅ Is File URL: \(url.isFileURL)")
            
            // Check if file is in Inbox (meaning asCopy worked)
            let isInInbox = url.path.contains("-Inbox")
            print("   📥 In App Inbox: \(isInInbox)")
            
            // Check if file is reachable
            let isReachable = (try? url.checkResourceIsReachable()) ?? false
            print("   📡 Is Reachable: \(isReachable)")
            
            // Check file size
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                print("   📦 File Size: \(formatter.string(fromByteCount: fileSize))")
            }
            
            processPDFDocument(url)
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    private func processPDFDocument(_ url: URL) {
        print("\n🔧 PROCESSING PDF...")
        
        // ✅ KEY FIX: Files in Inbox (from asCopy: true) don't need security-scoped access
        let isInInbox = url.path.contains("-Inbox") || url.path.contains("/tmp/")
        
        if isInInbox {
            print("✅ File is in app Inbox - direct access available")
            print("   (No security-scoped access needed)")
        } else {
            print("⚠️ File is external - attempting security-scoped access...")
            guard url.startAccessingSecurityScopedResource() else {
                print("   ❌ Security-scoped access failed")
                showErrorAlert("Cannot access the selected file")
                return
            }
            print("   ✅ Security-scoped access granted")
            defer {
                url.stopAccessingSecurityScopedResource()
                print("   ✅ Stopped security-scoped access")
            }
        }
        
        // Verify file exists and is readable
        print("\n⏳ Verifying file...")
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("   ❌ File does not exist")
            showErrorAlert("File does not exist")
            return
        }
        print("   ✅ File exists")
        
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            print("   ❌ File is not readable")
            showErrorAlert("File is not readable")
            return
        }
        print("   ✅ File is readable")
        
        // Copy file to permanent storage
        print("\n⏳ Copying to permanent storage...")
        do {
            let localURL = try copyPDFToAppDirectory(from: url)
            print("   ✅ Successfully copied to: \(localURL.lastPathComponent)")
            
            // Verify copied file
            guard FileManager.default.fileExists(atPath: localURL.path) else {
                print("   ❌ Copied file does not exist")
                showErrorAlert("Failed to verify copied file")
                return
            }
            print("   ✅ Copied file verified")
            
            // Generate thumbnail
            print("\n⏳ Generating thumbnail...")
            generatePDFThumbnail(for: localURL) { [weak self] thumbnail in
                guard let self = self else { return }
                
                if thumbnail != nil {
                    print("   ✅ Thumbnail generated")
                } else {
                    print("   ⚠️ Using placeholder")
                }
                
                DispatchQueue.main.async {
                    print("\n⏳ Adding to chat...")
                    let fileName = localURL.lastPathComponent
                    self.viewModel.sendPDF(url: localURL, thumbnail: thumbnail, fileName: fileName)
                    print("   ✅ Message added")
                    print("\n🎉 PDF PROCESSING COMPLETE! 🎉\n")
                    
                    // Clean up Inbox file after successful copy
                    if isInInbox {
                        try? FileManager.default.removeItem(at: url)
                        print("🗑️ Cleaned up Inbox file")
                    }
                }
            }
            
        } catch {
            print("   ❌ Error: \(error.localizedDescription)")
            showErrorAlert("Failed to process PDF: \(error.localizedDescription)")
        }
    }
    
    private func copyPDFToAppDirectory(from url: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // Create PDFs directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfDirectory = documentsPath.appendingPathComponent("PDFs", isDirectory: true)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: pdfDirectory.path) {
            try fileManager.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
            print("   📁 Created PDFs directory")
        }
        
        // Use original filename
        let fileName = url.lastPathComponent
        var destinationURL = pdfDirectory.appendingPathComponent(fileName)
        
        // Handle duplicate filenames
        var counter = 1
        while fileManager.fileExists(atPath: destinationURL.path) {
            let nameWithoutExtension = (fileName as NSString).deletingPathExtension
            let fileExtension = (fileName as NSString).pathExtension
            let uniqueName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
            destinationURL = pdfDirectory.appendingPathComponent(uniqueName)
            counter += 1
        }
        
        // Copy file
        try fileManager.copyItem(at: url, to: destinationURL)
        
        // Log file size
        if let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
           let fileSize = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            print("   📦 Size: \(formatter.string(fromByteCount: fileSize))")
        }
        
        return destinationURL
    }
    
    private func generatePDFThumbnail(for url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfDocument = PDFDocument(url: url),
               let page = pdfDocument.page(at: 0) {
                
                let pageRect = page.bounds(for: .mediaBox)
                let thumbnailSize = CGSize(width: 200, height: 280)
                
                let widthScale = thumbnailSize.width / pageRect.width
                let heightScale = thumbnailSize.height / pageRect.height
                let scale = min(widthScale, heightScale)
                
                let scaledSize = CGSize(
                    width: pageRect.width * scale,
                    height: pageRect.height * scale
                )
                
                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let thumbnail = renderer.image { context in
                    UIColor.white.set()
                    context.fill(CGRect(origin: .zero, size: scaledSize))
                    
                    context.cgContext.translateBy(x: 0, y: scaledSize.height)
                    context.cgContext.scaleBy(x: scale, y: -scale)
                    
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
                
                completion(thumbnail)
                return
            }
            
            // Fallback
            let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
            let placeholder = UIImage(systemName: "doc.fill", withConfiguration: config)
            completion(placeholder)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("📄 Document picker was cancelled")
    }
}


// MARK: - VoiceRecordingDelegate
extension ChatViewController: VoiceRecordingDelegate {
    func didFinishRecording(url: URL, duration: TimeInterval) {
        viewModel.sendAudio(url: url, duration: duration)
    }
    
    func didCancelRecording() {
        // Recording cancelled, no action needed
    }
    
    func didFailRecording(error: Error) {
        showAlert(title: "Recording Failed", message: error.localizedDescription)
    }
}

// MARK: - KeyboardManagerDelegate
extension ChatViewController: KeyboardManagerDelegate {
    func keyboardWillShow(height: CGFloat, duration: TimeInterval) {
        let bottomSafeArea = view.safeAreaInsets.bottom
        inputViewBottomConstraint.constant = height - bottomSafeArea
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: true)
        }
    }
    
    func keyboardWillHide(duration: TimeInterval) {
        inputViewBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - Alert Helper
private extension ChatViewController {
    func showAlert(title: String?, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

