//
//  LiveStreamViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 07/01/26.
//

import UIKit
import LiveKit
import AVFoundation

// MARK: - LiveStreamViewController

class LiveStreamViewController: UIViewController {
    
    // MARK: - Properties
    private var room: Room!
    private let token: String
    private let roomName: String
    private let streamTitle: String
    
    // State
    private var isStreaming = false
    private var isConnecting = false
    private var currentCameraPosition: AVCaptureDevice.Position = .front
    
    // MARK: - UI Components
    private lazy var localVideoView: VideoView = {
        let view = VideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layoutMode = .fill
        view.mirrorMode = .mirror
        view.isDebugMode = true  // Enable debug mode to see what's happening
        view.isEnabled = true
        return view
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "Starting stream..."
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var streamTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var liveStatusView: LiveStatusView = {
        LiveStatusView()
    }()
    
    private lazy var controlsView: StreamControlsView = {
        let view = StreamControlsView()
        view.delegate = self
        return view
    }()
    
    // MARK: - Initialization
    init(token: String, roomName: String, streamTitle: String) {
        self.token = token
        self.roomName = roomName
        self.streamTitle = streamTitle
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
        checkPermissionsAndConnect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task { await stopStreaming() }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        streamTitleLabel.text = streamTitle
        
        // Add subviews
        [localVideoView, liveStatusView, streamTitleLabel, statusLabel, controlsView].forEach {
            view.addSubview($0)
        }
        
        setupConstraints()
        liveStatusView.startAnimation()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Full screen video
            localVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            localVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            localVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            localVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Live status
            liveStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            liveStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            liveStatusView.heightAnchor.constraint(equalToConstant: 40),
            
            // Title
            streamTitleLabel.topAnchor.constraint(equalTo: liveStatusView.bottomAnchor, constant: 16),
            streamTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            streamTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Status
            statusLabel.topAnchor.constraint(equalTo: streamTitleLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Controls
            controlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controlsView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func setupRoom() {
        room = Room(delegate: self)
    }
    
    // MARK: - Streaming Logic
    private func checkPermissionsAndConnect() {
        PermissionManager.shared.checkMediaPermissions { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                Task {
                    await self.connectAndStartStream()
                }
            } else {
                self.showPermissionAlert()
            }
        }
    }
    
    private func connectAndStartStream() async {
        guard !isConnecting && !isStreaming else {
            print("⚠️ Already connecting or streaming")
            return
        }
        
        isConnecting = true
        
        do {
            // Step 1: Connect to room
            await updateStatus("Connecting to room...")
            print("🔌 Connecting to: wss://chatapp-74ccouhb.livekit.cloud")
            print("🎫 Token: \(token.prefix(20))...")
            
            try await room.connect(
                url: "wss://chatapp-74ccouhb.livekit.cloud",
                token: token
            )
            print("✅ Connected to room: \(roomName)")
            print("👥 Server version: \(room.serverVersion ?? "unknown")")
            
            // Step 2: Configure and enable camera
            await updateStatus("Starting camera...")
            try await enableCamera()
            
            // Step 3: Enable microphone
            await updateStatus("Starting audio...")
            try await enableMicrophone()
            
            // Update state
            isStreaming = true
            isConnecting = false
            await updateStatus("Live streaming")
            print("✅ Stream started successfully")
            
        } catch {
            isConnecting = false
            print("❌ Connection failed: \(error)")
            await handleConnectionError(error)
        }
    }
    
    private func enableCamera() async throws {
        print("📹 Enabling camera...")
        
        // Configure camera capture options
        let captureOptions = CameraCaptureOptions(
            position: .front,
            preferredFormat: nil,
            fps: 15
        )
        
        // Configure publish options
        let publishOptions = VideoPublishOptions(
            encoding: VideoEncoding(
                maxBitrate: 800_000,  // 800 kbps
                maxFps: 15
            ),
            simulcast: false
        )
        
        // Enable and publish camera through room
        try await room.localParticipant.setCamera(
            enabled: true,
            captureOptions: captureOptions,
            publishOptions: publishOptions
        )
        
        print("✅ Camera enabled and publishing")
        
        // IMPORTANT: Check if track exists immediately
        if let videoTrack = room.localParticipant.firstCameraVideoTrack {
            print("📹 Found video track immediately: \(videoTrack)")
            print("   Track dimensions: \(videoTrack.dimensions)")
//            print("   Track enabled: \(videoTrack.enabled)")
//            print("   Track muted: \(videoTrack.muted)")
            
            // Try attaching immediately
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("📹 Attaching track immediately to view")
                self.localVideoView.track = videoTrack
                self.localVideoView.setNeedsLayout()
                
                // Force a layout update
                self.view.layoutIfNeeded()
                
                print("📹 VideoView state after attach:")
                print("   isEnabled: \(self.localVideoView.isEnabled)")
                print("   isHidden: \(self.localVideoView.isHidden)")
                print("   bounds: \(self.localVideoView.bounds)")
            }
        } else {
            print("⚠️ No video track found immediately, will wait for didPublishTrack")
        }
    }
    
    private func enableMicrophone() async throws {
        let options = AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true
        )
        
        do {
            try await room.localParticipant.setMicrophone(
                enabled: true,
                captureOptions: options
            )
            print("✅ Microphone enabled")
        } catch {
            print("⚠️ Microphone failed, continuing with camera only: \(error)")
            // Don't throw - allow stream to continue with video only
        }
    }
    
    private func stopStreaming() async {
        guard isStreaming else { return }
        
        print("🛑 Stopping stream")
        isStreaming = false
        
        await MainActor.run {
            localVideoView.track = nil
        }
        
        await room.disconnect()
    }
    
    // MARK: - UI Updates
    private func updateStatus(_ message: String) async {
        await MainActor.run {
            statusLabel.text = message
        }
    }
    
    private func updateViewerCount(_ count: Int) {
        liveStatusView.updateViewerCount(count)
    }
    
    // MARK: - Error Handling
    private func handleConnectionError(_ error: Error) async {
        await MainActor.run {
            statusLabel.text = "Connection failed: \(error.localizedDescription)"
            
            let message: String
            if let lkError = error as? LiveKitError {
                switch lkError.code {
                case 100:
                    message = "Camera is unavailable. Please close other apps using the camera and try again."
                default:
                    message = lkError.localizedDescription
                }
            } else {
                message = error.localizedDescription
            }
            
            showAlert(title: "Connection Error", message: message)
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permissions Required",
            message: "Please enable Camera and Microphone access in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - RoomDelegate
extension LiveStreamViewController: RoomDelegate {
    
    func room(_ room: Room, localParticipant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        print("✅ Track published callback: \(publication.kind)")
        print("   Track SID: \(publication.sid)")
        print("   Track name: \(publication.name)")
        print("   Track source: \(publication.source)")
        
        // Only handle video tracks
        guard publication.kind == .video,
              let track = publication.track as? VideoTrack else {
            print("⚠️ Not a video track, skipping")
            return
        }
        
        print("📹 Video track details:")
        print("   Dimensions: \(track.dimensions)")
//        print("   Enabled: \(track.enabled)")
//        print("   Muted: \(track.muted)")
        
        // Attach video track to view on main thread using DispatchQueue (like LiveKit examples)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📹 Attaching video track to view from delegate")
            self.localVideoView.track = track
            
            // Force layout update
            self.localVideoView.setNeedsLayout()
            self.localVideoView.layoutIfNeeded()
            
            print("📹 VideoView state after attach:")
            print("   Current track: \(String(describing: self.localVideoView.track))")
            print("   isEnabled: \(self.localVideoView.isEnabled)")
            print("   isHidden: \(self.localVideoView.isHidden)")
            print("   alpha: \(self.localVideoView.alpha)")
            print("   superview: \(String(describing: self.localVideoView.superview))")
            print("   frame: \(self.localVideoView.frame)")
            print("   bounds: \(self.localVideoView.bounds)")
        }
    }
    
    func room(_ room: Room, localParticipant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) {
        print("⚠️ Track unpublished: \(publication.kind)")
        
        if publication.kind == .video {
            DispatchQueue.main.async { [weak self] in
                self?.localVideoView.track = nil
            }
        }
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        //print("👤 Viewer joined: \(participant.identity ?? "unknown")")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateViewerCount(room.remoteParticipants.count)
        }
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        //print("👤 Viewer left: \(participant.identity ?? "unknown")")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateViewerCount(room.remoteParticipants.count)
        }
    }
    
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        print("🔌 Connection state: \(oldValue) → \(connectionState)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch connectionState {
            case .connected:
                if !self.isStreaming {
                    self.statusLabel.text = "Connected"
                }
            case .reconnecting:
                self.statusLabel.text = "Reconnecting..."
            case .disconnected:
                self.statusLabel.text = "Disconnected"
                self.isStreaming = false
            default:
                break
            }
        }
    }
    
    func room(_ room: Room, didFailToConnectWithError error: Error) {
        print("❌ Failed to connect: \(error)")
        Task {
            await handleConnectionError(error)
        }
    }
    
    // Add track started callback for debugging
    func room(_ room: Room, track: Track, didUpdateMuted muted: Bool) {
        print("🔇 Track mute state changed: \(muted)")
    }
}

// MARK: - StreamControlsDelegate
extension LiveStreamViewController: StreamControlsDelegate {
    
    func didTapMuteButton() {
        Task {
            let isEnabled = room.localParticipant.isMicrophoneEnabled()
            try? await room.localParticipant.setMicrophone(enabled: !isEnabled)
            await MainActor.run {
                controlsView.updateMuteButton(isMuted: isEnabled)
            }
        }
    }
    
    func didTapVideoButton() {
        Task {
            let isEnabled = room.localParticipant.isCameraEnabled()
            print("📹 Toggling camera: currently \(isEnabled ? "enabled" : "disabled")")
            
            try? await room.localParticipant.setCamera(enabled: !isEnabled)
            
            await MainActor.run {
                controlsView.updateVideoButton(isOff: isEnabled)
                localVideoView.isHidden = isEnabled
                print("📹 Camera toggled to: \(isEnabled ? "disabled" : "enabled")")
            }
        }
    }
    
    func didTapSwitchCamera() {
        Task {
            guard let track = room.localParticipant.firstCameraVideoTrack as? LocalVideoTrack,
                  let capturer = track.capturer as? CameraCapturer else {
                print("⚠️ Cannot switch camera: track or capturer not available")
                return
            }
            
            do {
                try await capturer.switchCameraPosition()
                await MainActor.run {
                    currentCameraPosition = currentCameraPosition == .front ? .back : .front
                    print("✅ Switched to \(currentCameraPosition == .front ? "front" : "back") camera")
                }
            } catch {
                print("❌ Failed to switch camera: \(error)")
            }
        }
    }
    
    func didTapEndStream() {
        let alert = UIAlertController(
            title: "End Stream",
            message: "Are you sure you want to end the stream?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End", style: .destructive) { [weak self] _ in
            Task {
                await self?.stopStreaming()
                await MainActor.run {
                    self?.dismiss(animated: true)
                }
            }
        })
        
        present(alert, animated: true)
    }
}
