//
//  LiveStreamViewerViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 07/01/26.
//


import UIKit
import LiveKit

class LiveStreamViewerViewController: UIViewController {
    
    // MARK: - Properties
    private var room: Room!
    private let token: String
    private let roomName: String
    private let streamTitle: String
    private let streamerName: String
    
    // MARK: - UI Components
    private lazy var remoteVideoView: VideoView = {
        let view = VideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layoutMode = .fill
        view.isDebugMode = true  // Enable debug mode to see track info
        view.isEnabled = true
        view.clipsToBounds = true
        return view
    }()
    
    private let overlayContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let statusContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let liveIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let liveLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "LIVE"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .bold)
        return label
    }()
    
    private let viewerCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.text = "0"
        return label
    }()
    
    private let viewerIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        imageView.image = UIImage(systemName: "eye.fill", withConfiguration: config)
        return imageView
    }()
    
    private let streamerNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private let streamTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white.withAlphaComponent(0.9)
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "Connecting..."
        label.numberOfLines = 0
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        return indicator
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let bottomControlsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return view
    }()
    
    private lazy var muteButton: UIButton = {
        let button = createControlButton(
            iconName: "speaker.wave.3.fill",
            backgroundColor: .systemGray
        )
        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Track mute state
    private var isAudioMuted = false
    
    // MARK: - Init
    init(token: String, roomName: String, streamTitle: String, streamerName: String) {
        self.token = token
        self.roomName = roomName
        self.streamTitle = streamTitle
        self.streamerName = streamerName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRoom()
        joinStream()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            await leaveStream()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        streamerNameLabel.text = streamerName
        streamTitleLabel.text = streamTitle
        
        // Add views
        view.addSubview(remoteVideoView)
        view.addSubview(overlayContainer)
        view.addSubview(loadingIndicator)
        view.addSubview(bottomControlsContainer)
        
        // Status container setup
        overlayContainer.addSubview(statusContainer)
        statusContainer.addSubview(liveIndicator)
        statusContainer.addSubview(liveLabel)
        statusContainer.addSubview(viewerIcon)
        statusContainer.addSubview(viewerCountLabel)
        
        overlayContainer.addSubview(streamerNameLabel)
        overlayContainer.addSubview(streamTitleLabel)
        overlayContainer.addSubview(statusLabel)
        overlayContainer.addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Bottom controls
        bottomControlsContainer.addSubview(muteButton)
        
        loadingIndicator.startAnimating()
        
        // Layout
        NSLayoutConstraint.activate([
            // Video view (full screen)
            remoteVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Overlay
            overlayContainer.topAnchor.constraint(equalTo: view.topAnchor),
            overlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayContainer.bottomAnchor.constraint(equalTo: bottomControlsContainer.topAnchor),
            
            // Status container
            statusContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusContainer.heightAnchor.constraint(equalToConstant: 40),
            
            // Live indicator
            liveIndicator.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 12),
            liveIndicator.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            liveIndicator.widthAnchor.constraint(equalToConstant: 8),
            liveIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // Live label
            liveLabel.leadingAnchor.constraint(equalTo: liveIndicator.trailingAnchor, constant: 6),
            liveLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            
            // Viewer icon
            viewerIcon.leadingAnchor.constraint(equalTo: liveLabel.trailingAnchor, constant: 12),
            viewerIcon.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            viewerIcon.widthAnchor.constraint(equalToConstant: 16),
            viewerIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Viewer count
            viewerCountLabel.leadingAnchor.constraint(equalTo: viewerIcon.trailingAnchor, constant: 6),
            viewerCountLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            viewerCountLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -12),
            
            // Streamer name
            streamerNameLabel.topAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: 16),
            streamerNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            streamerNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Stream title
            streamTitleLabel.topAnchor.constraint(equalTo: streamerNameLabel.bottomAnchor, constant: 4),
            streamTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            streamTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Status label
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: bottomControlsContainer.topAnchor, constant: -20),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Bottom controls
            bottomControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomControlsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomControlsContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Mute button
            muteButton.centerXAnchor.constraint(equalTo: bottomControlsContainer.centerXAnchor),
            muteButton.centerYAnchor.constraint(equalTo: bottomControlsContainer.centerYAnchor)
        ])
        
        // Start blinking animation
        animateLiveIndicator()
    }
    
    private func setupRoom() {
        room = Room(delegate: self)
    }
    
    private func joinStream() {
        Task {
            do {
                print("🔌 Connecting to stream...")
                print("   URL: wss://chatapp-74ccouhb.livekit.cloud")
                print("   Room: \(roomName)")
                print("   Token: \(token.prefix(20))...")
                
                try await room.connect(
                    url: "wss://chatapp-74ccouhb.livekit.cloud",
                    token: token
                )
                
                print("✅ Connected to stream")
                print("👥 Server version: \(room.serverVersion ?? "unknown")")
                print("👥 Remote participants: \(room.remoteParticipants.count)")
                
                // List all participants
                for (_, participant) in room.remoteParticipants {
                    //print("   Participant: \(participant.identity ?? "unknown")")
                    print("   Video tracks: \(participant.videoTracks.count)")
                    print("   Audio tracks: \(participant.audioTracks.count)")
                    
                    // Check for existing tracks
                    for publication in participant.videoTracks {
                        print("   Video track found: \(publication.sid)")
//                        print("      Subscribed: \(publication.subscribed)")
//                        print("      Enabled: \(publication.enabled)")
                        
                        if let track = publication.track as? VideoTrack {
                            print("      Track dimensions: \(track.dimensions)")
//                            print("      Track muted: \(track.muted)")
                            
                            // Try attaching immediately if track exists
                            DispatchQueue.main.async { [weak self] in
                                self?.attachVideoTrack(track)
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    statusLabel.text = "Watching live"
                    loadingIndicator.stopAnimating()
                    updateViewerCount(room.remoteParticipants.count + 1)
                }
            } catch {
                print("❌ Failed to connect: \(error)")
                await MainActor.run {
                    statusLabel.text = "Failed to connect: \(error.localizedDescription)"
                    loadingIndicator.stopAnimating()
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func leaveStream() async {
        print("🔌 Leaving stream")
        await room.disconnect()
    }
    
    private func attachVideoTrack(_ track: VideoTrack) {
        print("📹 Attaching video track to viewer")
        print("   Track dimensions: \(track.dimensions)")
//        print("   Track enabled: \(track.enabled)")
//        print("   Track muted: \(track.muted)")
        
        // CORRECT API: Set the track property, don't use add(videoRenderer:)
        remoteVideoView.track = track
        
        // Force layout update
        remoteVideoView.setNeedsLayout()
        remoteVideoView.layoutIfNeeded()
        
        loadingIndicator.stopAnimating()
        statusLabel.text = ""
        
        print("📹 VideoView state after attach:")
        print("   Current track: \(String(describing: remoteVideoView.track))")
        print("   isEnabled: \(remoteVideoView.isEnabled)")
        print("   isHidden: \(remoteVideoView.isHidden)")
        print("   frame: \(remoteVideoView.frame)")
    }
    
    // MARK: - Actions
    @objc private func muteButtonTapped() {
        isAudioMuted.toggle()
        
        // Update button appearance
        let iconName = isAudioMuted ? "speaker.slash.fill" : "speaker.wave.3.fill"
        let backgroundColor: UIColor = isAudioMuted ? .systemRed : .systemGray
        updateButton(muteButton, iconName: iconName, backgroundColor: backgroundColor)
        
        // Mute/unmute audio by controlling subscription
        // Note: This unsubscribes from audio, which is more efficient than just muting locally
        Task {
            for participant in room.remoteParticipants.values {
                for publication in participant.audioTracks {
                    guard let remotePublication = publication as? RemoteTrackPublication else { continue }
                    
                    do {
                        // Unsubscribe = stop receiving audio (saves bandwidth)
                        // Subscribe = start receiving audio again
                        try await remotePublication.set(subscribed: !isAudioMuted)
                        //print("🔇 Audio \(isAudioMuted ? "muted (unsubscribed)" : "unmuted (subscribed)") for \(participant.identity ?? "unknown")")
                    } catch {
                        print("❌ Failed to toggle audio subscription: \(error)")
                    }
                }
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        Task {
            await leaveStream()
            await MainActor.run {
                dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Helpers
    private func createControlButton(iconName: String, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 32
        button.tintColor = .white
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        
        button.widthAnchor.constraint(equalToConstant: 64).isActive = true
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        return button
    }
    
    private func updateButton(_ button: UIButton, iconName: String, backgroundColor: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        button.backgroundColor = backgroundColor
    }
    
    private func animateLiveIndicator() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse]) {
            self.liveIndicator.alpha = 0.3
        }
    }
    
    private func updateViewerCount(_ count: Int) {
        viewerCountLabel.text = "\(count)"
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Connection Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - RoomDelegate
extension LiveStreamViewerViewController: RoomDelegate {
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        print("✅ Subscribed to track: \(publication.kind)")
        print("   Track SID: \(publication.sid)")
//        print("   Participant: \(participant.identity ?? "unknown")")
        
        guard publication.kind == .video,
              let videoTrack = publication.track as? VideoTrack else {
            print("⚠️ Not a video track, skipping")
            return
        }
        
        print("📹 Video track details:")
        print("   Dimensions: \(videoTrack.dimensions)")
//        print("   Enabled: \(videoTrack.enabled)")
//        print("   Muted: \(videoTrack.muted)")
        
        // Attach track on main thread using DispatchQueue (LiveKit pattern)
        DispatchQueue.main.async { [weak self] in
            self?.attachVideoTrack(videoTrack)
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        print("📹 Unsubscribed from track: \(publication.kind)")
        
        if publication.kind == .video {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.remoteVideoView.track = nil
                self.statusLabel.text = "Stream ended"
                self.loadingIndicator.stopAnimating()
                
                // Auto-dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.dismiss(animated: true)
                }
            }
        }
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        //print("👤 Participant connected: \(participant.identity ?? "unknown")")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Count includes remote participants + ourselves
            self.updateViewerCount(room.remoteParticipants.count + 1)
        }
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        //print("👤 Participant disconnected: \(participant.identity ?? "unknown")")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateViewerCount(room.remoteParticipants.count + 1)
        }
    }
    
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        print("🔌 Connection state: \(oldValue) → \(connectionState)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch connectionState {
            case .connected:
                self.statusLabel.text = "Watching live"
                self.loadingIndicator.stopAnimating()
            case .reconnecting:
                self.statusLabel.text = "Reconnecting..."
                self.loadingIndicator.startAnimating()
            case .disconnected:
                self.statusLabel.text = "Disconnected"
                self.loadingIndicator.stopAnimating()
            default:
                break
            }
        }
    }
    
    func room(_ room: Room, didFailToConnectWithError error: Error) {
        print("❌ Failed to connect: \(error)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusLabel.text = "Connection failed"
            self.loadingIndicator.stopAnimating()
            self.showErrorAlert(message: error.localizedDescription)
        }
    }
}

