//
//  VideoCallViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 07/01/26.
//


import UIKit
import LiveKit

class VideoCallViewController: UIViewController {
    
    private var room: Room!
    private var localVideoView: VideoView!
    private var remoteVideoView: VideoView!
    private var participants: [RemoteParticipant] = []
    
    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let disconnectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Disconnect", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupRoom()
        setupVideoViews()
        setupButtons()
    }
    
    private func setupRoom() {
        room = Room(delegate: self)
    }
    
    private func setupVideoViews() {
        // Local video view (small, top-right corner)
        localVideoView = VideoView()
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        localVideoView.layer.cornerRadius = 8
        localVideoView.clipsToBounds = true
        view.addSubview(localVideoView)
        
        // Remote video view (full screen)
        remoteVideoView = VideoView()
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(remoteVideoView)
        
        NSLayoutConstraint.activate([
            // Remote video (full screen)
            remoteVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Local video (corner)
            localVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            localVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            localVideoView.widthAnchor.constraint(equalToConstant: 120),
            localVideoView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }
    
    private func setupButtons() {
        let stackView = UIStackView(arrangedSubviews: [connectButton, disconnectButton])
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
    }
    
    @objc private func connectTapped() {
        Task {
            await connect()
        }
    }
    
    @objc private func disconnectTapped() {
        Task {
            await disconnect()
        }
    }
    
    private func connect() async {
        do {
            // Replace with your LiveKit server URL and token
            let url = "wss://your-livekit-server.com"
            let token = "your-jwt-token"
            
            try await room.connect(url: url, token: token)
            
            // Enable camera and microphone
            try await room.localParticipant.setCamera(enabled: true)
            try await room.localParticipant.setMicrophone(enabled: true)
            
            // Attach local video track to view
            if let videoTrack = room.localParticipant.firstCameraVideoTrack {
                await videoTrack.add(videoRenderer: localVideoView)
            }
            
            print("Connected to room")
        } catch {
            print("Failed to connect: \(error)")
        }
    }
    
    private func disconnect() async {
        await room.disconnect()
        print("Disconnected from room")
    }
}

// MARK: - RoomDelegate
extension VideoCallViewController: RoomDelegate {
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        guard let track = publication.track as? VideoTrack else { return }
        
        Task { @MainActor in
            await track.add(videoRenderer: remoteVideoView)
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        if let track = publication.track as? VideoTrack {
            Task { @MainActor in
                await track.remove(videoRenderer: remoteVideoView)
            }
        }
        print("Participant unsubscribed from track")
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        participants.append(participant)
        print("Participant joined: \(participant.identity.map(String.init) ?? "Unknown")")
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        participants.removeAll { $0.sid == participant.sid }
        print("Participant left: \(participant.identity.map(String.init) ?? "Unknown")")
    }
    
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        print("Connection state changed: \(connectionState)")
    }
}

