//
//  AudioCallManager.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 06/01/26.
//

import TwilioVideo
import AVFoundation
import UIKit

protocol AudioCallManagerDelegate: AnyObject {
    func didConnectToRoom()
    func didDisconnectFromRoom()
    func didFailToConnectToRoom(error: Error)
    func participantDidConnect(participant: RemoteParticipant)
    func participantDidDisconnect(participant: RemoteParticipant)
}

class AudioCallManager: NSObject {
    static let shared = AudioCallManager()
    
    weak var delegate: AudioCallManagerDelegate?
    
    var room: Room?
    var localAudioTrack: LocalAudioTrack?
    var remoteParticipant: RemoteParticipant?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup Local Audio
    
    func setupLocalAudio() {
        print("🎤 Setting up local audio...")
        
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("✅ Microphone permission granted")
                DispatchQueue.main.async {
                    self.createAudioTrack()
                }
            } else {
                print("❌ Microphone permission denied")
            }
        }
    }
    
    private func createAudioTrack() {
        // Setup audio
        localAudioTrack = LocalAudioTrack(options: nil, enabled: true, name: "Microphone")
        
        if localAudioTrack != nil {
            print("✅ Audio track created")
        } else {
            print("❌ Failed to create audio track")
        }
    }
    
    // MARK: - Connect to Room
    
    func connectToRoom(token: String, roomName: String) {
        print("🔗 Connecting to audio room: \(roomName)")
        
        let connectOptions = ConnectOptions(token: token) { builder in
            builder.roomName = roomName
            
            // Add audio track only
            if let localAudioTrack = self.localAudioTrack {
                builder.audioTracks = [localAudioTrack]
                print("✅ Added audio track to connection")
            } else {
                print("⚠️ No audio track available")
            }
            
            // Disable video
            builder.isAutomaticSubscriptionEnabled = true
        }
        
        room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
    }
    
    // MARK: - Disconnect
    
    func disconnect() {
        print("📞 Disconnecting from audio room...")
        room?.disconnect()
        cleanupLocalMedia()
    }
    
    private func cleanupLocalMedia() {
        print("🧹 Cleaning up local audio...")
        localAudioTrack = nil
        print("✅ Cleanup complete")
    }
    
    // MARK: - Audio Controls
    
    func toggleLocalAudio() -> Bool {
        guard let localAudioTrack = localAudioTrack else {
            print("⚠️ No audio track to toggle")
            return false
        }
        
        localAudioTrack.isEnabled = !localAudioTrack.isEnabled
        print("🎤 Audio \(localAudioTrack.isEnabled ? "enabled" : "disabled")")
        return localAudioTrack.isEnabled
    }
    
    func toggleSpeaker(_ enable: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if enable {
                try audioSession.overrideOutputAudioPort(.speaker)
                print("🔊 Speaker enabled")
            } else {
                try audioSession.overrideOutputAudioPort(.none)
                print("📱 Speaker disabled (using earpiece)")
            }
        } catch {
            print("❌ Failed to toggle speaker: \(error.localizedDescription)")
        }
    }
}

// MARK: - RoomDelegate
extension AudioCallManager: RoomDelegate {
    func roomDidConnect(room: Room) {
        print("✅ Connected to audio room: \(room.name)")
        
        // Handle existing participants
        if let remoteParticipant = room.remoteParticipants.first {
            self.remoteParticipant = remoteParticipant
            remoteParticipant.delegate = self
            print("👤 Found existing participant: \(remoteParticipant.identity)")
        }
        
        delegate?.didConnectToRoom()
    }
    
    func roomDidDisconnect(room: Room, error: Error?) {
        print("📞 Disconnected from audio room")
        self.remoteParticipant = nil
        self.room = nil
        
        if let error = error {
            print("❌ Disconnect error: \(error.localizedDescription)")
        }
        
        delegate?.didDisconnectFromRoom()
    }
    
    func roomDidFailToConnect(room: Room, error: Error) {
        print("❌ Failed to connect: \(error.localizedDescription)")
        self.room = nil
        delegate?.didFailToConnectToRoom(error: error)
    }
    
    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        print("👤 Participant connected: \(participant.identity)")
        self.remoteParticipant = participant
        participant.delegate = self
        delegate?.participantDidConnect(participant: participant)
    }
    
    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        print("👋 Participant disconnected: \(participant.identity)")
        self.remoteParticipant = nil
        delegate?.participantDidDisconnect(participant: participant)
    }
}

// MARK: - RemoteParticipantDelegate
extension AudioCallManager: RemoteParticipantDelegate {
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        print("🎤 Subscribed to audio track from \(participant.identity)")
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        print("🎤 Unsubscribed from audio track from \(participant.identity)")
    }
}
