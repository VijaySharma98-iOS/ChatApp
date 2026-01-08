//
//  VideoCallViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 05/01/26.
//


//import UIKit
//import TwilioVideo
//
//class VideoCallViewController: UIViewController {
//    
//    // MARK: - UI Components
//    private let remoteVideoView: VideoView = {
//        let view = VideoView()
//        view.contentMode = .scaleAspectFill
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let localVideoView: VideoView = {
//        let view = VideoView()
//        view.contentMode = .scaleAspectFill
//        view.layer.cornerRadius = 12
//        view.clipsToBounds = true
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let callerNameLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 24, weight: .semibold)
//        label.textColor = .white
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let statusLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 16, weight: .regular)
//        label.textColor = .white
//        label.textAlignment = .center
//        label.text = "Connecting..."
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let controlsStackView: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .horizontal
//        stack.distribution = .fillEqually
//        stack.spacing = 20
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        return stack
//    }()
//    
//    private lazy var muteButton: UIButton = {
//        let button = createControlButton(
//            image: UIImage(systemName: "mic.fill"),
//            backgroundColor: .systemGray
//        )
//        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    private lazy var videoButton: UIButton = {
//        let button = createControlButton(
//            image: UIImage(systemName: "video.fill"),
//            backgroundColor: .systemGray
//        )
//        button.addTarget(self, action: #selector(videoButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    private lazy var flipButton: UIButton = {
//        let button = createControlButton(
//            image: UIImage(systemName: "camera.rotate"),
//            backgroundColor: .systemGray
//        )
//        button.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    private lazy var endCallButton: UIButton = {
//        let button = createControlButton(
//            image: UIImage(systemName: "phone.down.fill"),
//            backgroundColor: .systemRed
//        )
//        button.addTarget(self, action: #selector(endCallButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    private lazy var switchRoomButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Switch Room", for: .normal)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemBlue.withAlphaComponent(0.8)
//        button.layer.cornerRadius = 8
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.addTarget(self, action: #selector(switchRoomButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    private lazy var shareButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
//        button.tintColor = .white
//        button.backgroundColor = .systemBlue.withAlphaComponent(0.8)
//        button.layer.cornerRadius = 20
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    private lazy var copyLinkButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("📋 Copy Link", for: .normal)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemGreen.withAlphaComponent(0.8)
//        button.layer.cornerRadius = 8
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.addTarget(self, action: #selector(copyLinkButtonTapped), for: .touchUpInside)
//        return button
//    }()
//    
//    // MARK: - Properties
//    private let token: String
//    private let roomName: String
//    private let callerName: String
//    private let userIdentity: String
//    private var isAudioMuted = false
//    private var isVideoMuted = false
//    
//    // MARK: - Init
//    init(token: String, roomName: String, callerName: String, userIdentity: String = "user-\(UUID().uuidString)") {
//        self.token = token
//        self.roomName = roomName
//        self.callerName = callerName
//        self.userIdentity = userIdentity
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupVideo()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        if isBeingDismissed {
//            VideoManager.shared.disconnect()
//        }
//    }
//    
//    // MARK: - Setup
//    private func setupUI() {
//        view.backgroundColor = .black
//        
//        callerNameLabel.text = callerName
//        
//        view.addSubview(remoteVideoView)
//        view.addSubview(localVideoView)
//        view.addSubview(callerNameLabel)
//        view.addSubview(statusLabel)
//        view.addSubview(controlsStackView)
//        view.addSubview(switchRoomButton)
//        view.addSubview(shareButton)
//        view.addSubview(copyLinkButton)
//        
//        controlsStackView.addArrangedSubview(muteButton)
//        controlsStackView.addArrangedSubview(videoButton)
//        controlsStackView.addArrangedSubview(flipButton)
//        controlsStackView.addArrangedSubview(endCallButton)
//        
//        NSLayoutConstraint.activate([
//            remoteVideoView.topAnchor.constraint(equalTo: view.topAnchor),
//            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            remoteVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            callerNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
//            callerNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            
//            statusLabel.topAnchor.constraint(equalTo: callerNameLabel.bottomAnchor, constant: 8),
//            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            
//            localVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            localVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            localVideoView.widthAnchor.constraint(equalToConstant: 120),
//            localVideoView.heightAnchor.constraint(equalToConstant: 160),
//            
//            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            shareButton.widthAnchor.constraint(equalToConstant: 40),
//            shareButton.heightAnchor.constraint(equalToConstant: 40),
//            
//            controlsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
//            controlsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            controlsStackView.heightAnchor.constraint(equalToConstant: 60),
//            controlsStackView.widthAnchor.constraint(equalToConstant: 320),
//            
//            switchRoomButton.topAnchor.constraint(equalTo: localVideoView.bottomAnchor, constant: 20),
//            switchRoomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            switchRoomButton.widthAnchor.constraint(equalToConstant: 120),
//            switchRoomButton.heightAnchor.constraint(equalToConstant: 40),
//            
//            copyLinkButton.topAnchor.constraint(equalTo: switchRoomButton.bottomAnchor, constant: 10),
//            copyLinkButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            copyLinkButton.widthAnchor.constraint(equalToConstant: 120),
//            copyLinkButton.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }
//    
//    private func setupVideo() {
//        VideoManager.shared.delegate = self
//        VideoManager.shared.setupLocalMedia()
//        VideoManager.shared.connectToRoom(token: token, roomName: roomName)
//    }
//    
//    // MARK: - Room Link Generation
//    
//    private func getCurrentRoomLink() -> URL? {
//        return TokenService.shared.createVideoRoomLink(
//            roomName: roomName,
//            userName: userIdentity
//        )
//    }
//    
//    @objc private func shareButtonTapped() {
//        guard let roomLink = getCurrentRoomLink() else {
//            showError(message: "Failed to generate room link")
//            return
//        }
//        
//        let message = "Join my video call: \(roomLink.absoluteString)"
//        let activityVC = UIActivityViewController(
//            activityItems: [message],
//            applicationActivities: nil
//        )
//        
//        // For iPad support
//        if let popoverController = activityVC.popoverPresentationController {
//            popoverController.sourceView = shareButton
//            popoverController.sourceRect = shareButton.bounds
//        }
//        
//        present(activityVC, animated: true)
//    }
//    
//    @objc private func copyLinkButtonTapped() {
//        guard let roomLink = getCurrentRoomLink() else {
//            showError(message: "Failed to generate room link")
//            return
//        }
//        
//        UIPasteboard.general.string = roomLink.absoluteString
//        
//        // Show success feedback
//        showSuccessToast(message: "Link copied to clipboard!")
//    }
//    
//    @objc private func switchRoomButtonTapped() {
//        let alert = UIAlertController(
//            title: "Switch Room",
//            message: "Enter the new room name",
//            preferredStyle: .alert
//        )
//        
//        alert.addTextField { textField in
//            textField.placeholder = "Room name"
//        }
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        alert.addAction(UIAlertAction(title: "Switch", style: .default) { [weak self] _ in
//            guard let self = self,
//                  let newRoomName = alert.textFields?.first?.text,
//                  !newRoomName.isEmpty else {
//                return
//            }
//            
//            self.fetchTokenAndSwitchRoom(roomName: newRoomName)
//        })
//        
//        present(alert, animated: true)
//    }
//    
//    private func fetchTokenAndSwitchRoom(roomName: String) {
//        statusLabel.text = "Switching room..."
//        statusLabel.alpha = 1
//        
//        TokenService.shared.fetchToken(identity: userIdentity, roomName: roomName) { [weak self] result in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let token):
//                    VideoManager.shared.switchRoom(token: token, newRoomName: roomName)
//                    self.statusLabel.text = "Switched to \(roomName)"
//                    
//                    // Update the room name property
//                    // Note: You might want to make roomName mutable or use a different approach
//                    
//                    UIView.animate(withDuration: 2.0, delay: 1.0) {
//                        self.statusLabel.alpha = 0
//                    }
//                    
//                case .failure(let error):
//                    self.showError(message: "Failed to switch room: \(error.localizedDescription)")
//                    self.statusLabel.text = "Switch failed"
//                    self.statusLabel.alpha = 0
//                }
//            }
//        }
//    }
//    
//    private func showError(message: String) {
//        let alert = UIAlertController(
//            title: "Error",
//            message: message,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//    
//    private func showSuccessToast(message: String) {
//        let toastLabel = UILabel()
//        toastLabel.text = message
//        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
//        toastLabel.textColor = .white
//        toastLabel.textAlignment = .center
//        toastLabel.backgroundColor = .systemGreen.withAlphaComponent(0.9)
//        toastLabel.layer.cornerRadius = 8
//        toastLabel.clipsToBounds = true
//        toastLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(toastLabel)
//        
//        NSLayoutConstraint.activate([
//            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            toastLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -20),
//            toastLabel.widthAnchor.constraint(equalToConstant: 200),
//            toastLabel.heightAnchor.constraint(equalToConstant: 40)
//        ])
//        
//        toastLabel.alpha = 0
//        UIView.animate(withDuration: 0.3) {
//            toastLabel.alpha = 1
//        }
//        
//        UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
//            toastLabel.alpha = 0
//        } completion: { _ in
//            toastLabel.removeFromSuperview()
//        }
//    }
//    
//    private func createControlButton(image: UIImage?, backgroundColor: UIColor) -> UIButton {
//        let button = UIButton(type: .system)
//        button.setImage(image, for: .normal)
//        button.tintColor = .white
//        button.backgroundColor = backgroundColor
//        button.layer.cornerRadius = 30
//        button.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            button.widthAnchor.constraint(equalToConstant: 60),
//            button.heightAnchor.constraint(equalToConstant: 60)
//        ])
//        
//        return button
//    }
//    
//    // MARK: - Actions
//    @objc private func muteButtonTapped() {
//        isAudioMuted = !VideoManager.shared.toggleLocalAudio()
//        let imageName = isAudioMuted ? "mic.slash.fill" : "mic.fill"
//        muteButton.setImage(UIImage(systemName: imageName), for: .normal)
//        muteButton.backgroundColor = isAudioMuted ? .systemRed : .systemGray
//    }
//    
//    @objc private func videoButtonTapped() {
//        isVideoMuted = !VideoManager.shared.toggleLocalVideo()
//        let imageName = isVideoMuted ? "video.slash.fill" : "video.fill"
//        videoButton.setImage(UIImage(systemName: imageName), for: .normal)
//        videoButton.backgroundColor = isVideoMuted ? .systemRed : .systemGray
//    }
//    
//    @objc private func flipButtonTapped() {
//        VideoManager.shared.flipCamera()
//    }
//    
//    @objc private func endCallButtonTapped() {
//        VideoManager.shared.disconnect()
//        dismiss(animated: true)
//    }
//}
//
//// MARK: - VideoManagerDelegate
//extension VideoCallViewController: VideoManagerDelegate {
//    
//    func localVideoTrackDidStart() {
//        DispatchQueue.main.async {
//            if let localVideoTrack = VideoManager.shared.localVideoTrack {
//                localVideoTrack.addRenderer(self.localVideoView)
//                print("✅ Local video renderer added")
//            }
//        }
//    }
//    
//    func didConnectToRoom() {
//        DispatchQueue.main.async {
//            self.statusLabel.text = "Connected"
//            
//            UIView.animate(withDuration: 2.0, delay: 1.0) {
//                self.statusLabel.alpha = 0
//            }
//        }
//    }
//    
//    func didDisconnectFromRoom() {
//        DispatchQueue.main.async {
//            self.dismiss(animated: true)
//        }
//    }
//    
//    func didFailToConnectToRoom(error: Error) {
//        DispatchQueue.main.async {
//            let alert = UIAlertController(
//                title: "Connection Failed",
//                message: error.localizedDescription,
//                preferredStyle: .alert
//            )
//            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//                self.dismiss(animated: true)
//            })
//            self.present(alert, animated: true)
//        }
//    }
//    
//    func participantDidConnect(participant: RemoteParticipant) {
//        print("Participant connected: \(participant.identity)")
//    }
//    
//    func participantDidDisconnect(participant: RemoteParticipant) {
//        DispatchQueue.main.async {
//            self.statusLabel.text = "Call ended"
//            self.statusLabel.alpha = 1
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                self.dismiss(animated: true)
//            }
//        }
//    }
//    
//    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, participant: RemoteParticipant) {
//        DispatchQueue.main.async {
//            videoTrack.addRenderer(self.remoteVideoView)
//        }
//    }
//}
