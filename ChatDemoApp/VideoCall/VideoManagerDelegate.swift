//
//  VideoManagerDelegate.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 05/01/26.
//

// VideoManager.swift
import TwilioVideo
import UIKit
import AVFoundation

protocol VideoManagerDelegate: AnyObject {
    func didConnectToRoom()
    func didDisconnectFromRoom()
    func didFailToConnectToRoom(error: Error)
    func participantDidConnect(participant: RemoteParticipant)
    func participantDidDisconnect(participant: RemoteParticipant)
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, participant: RemoteParticipant)
    func localVideoTrackDidStart()
}

class VideoManager: NSObject {
    static let shared = VideoManager()
    
    weak var delegate: VideoManagerDelegate?
    
    var room: Room?
    var camera: CameraSource?
    var localVideoTrack: LocalVideoTrack?
    var localAudioTrack: LocalAudioTrack?
    var remoteParticipant: RemoteParticipant?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup Local Media
    
    func setupLocalMedia() {
        print("🎥 Setting up local media...")
        
        // Request camera permission first
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("✅ Camera permission granted")
                DispatchQueue.main.async {
                    self.setupCamera()
                }
            } else {
                print("❌ Camera permission denied")
            }
        }
        
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("✅ Microphone permission granted")
                DispatchQueue.main.async {
                    self.setupAudio()
                }
            } else {
                print("❌ Microphone permission denied")
            }
        }
    }
    
    private func setupCamera() {
        // Setup camera source
        let options = CameraSourceOptions { _ in
            // Configuration can be added here if needed
        }

        if let camera = CameraSource(options: options, delegate: self) {
            self.camera = camera

            // Create local video track
            localVideoTrack = LocalVideoTrack(source: camera, enabled: true, name: "Camera")

            // Select front camera when starting capture
            let desiredPosition: AVCaptureDevice.Position = .front
            guard let device = CameraSource.captureDevice(position: desiredPosition) else {
                print("❌ No capture device found for position: \(desiredPosition)")
                return
            }

            // Choose a supported video format (prefer 720p if available)
            let supportedFormats = CameraSource.supportedFormats(captureDevice: device)
            var preferredFormat: VideoFormat?
            
            // Convert NSOrderedSet to sequence of VideoFormat and find preferred 720p format
            for case let format as VideoFormat in supportedFormats {
                let dims = format.dimensions
                if (dims.width == 1280 && dims.height == 720) || (dims.width == 720 && dims.height == 1280) {
                    preferredFormat = format
                    break
                }
            }
            
            // If no 720p format found, use the first available VideoFormat
            if preferredFormat == nil {
                preferredFormat = supportedFormats.firstObject as? VideoFormat
            }

            guard let format = preferredFormat else {
                print("❌ No supported video formats available for camera")
                return
            }

            camera.startCapture(device: device, format: format) { captureDevice, videoFormat, error in
                if let error = error {
                    print("❌ Failed to start camera: \(error.localizedDescription)")
                } else {
                    let dims = videoFormat.dimensions
                    print("✅ Camera started successfully with format: \(dims.width)x\(dims.height)")
                    
                    // Notify delegate that local video is ready
                    DispatchQueue.main.async {
                        self.delegate?.localVideoTrackDidStart()
                    }
                }
            }
        } else {
            print("❌ Failed to create camera source")
        }
    }
    
    private func setupAudio() {
        // Setup audio
        localAudioTrack = LocalAudioTrack(options: nil, enabled: true, name: "Microphone")
        
        if localAudioTrack != nil {
            print("✅ Audio track created")
        } else {
            print("❌ Failed to create audio track")
        }
    }
    func switchRoom(token: String, newRoomName: String) {
        print("🔄 Switching to room: \(newRoomName)")
        
        // Disconnect from current room without cleaning up local media
        if let currentRoom = room {
            currentRoom.disconnect()
            room = nil
            remoteParticipant = nil
        }
        
        // Connect to new room with existing local tracks
        connectToRoom(token: token, roomName: newRoomName)
    }
    
    // MARK: - Connect to Room
    
    func connectToRoom(token: String, roomName: String) {
        print("🔗 Connecting to room: \(roomName)")
        
        let connectOptions = ConnectOptions(token: token) { builder in
            builder.roomName = roomName
            
            // Add video track if available
            if let localVideoTrack = self.localVideoTrack {
                builder.videoTracks = [localVideoTrack]
                print("✅ Added video track to connection")
            } else {
                print("⚠️ No video track available")
            }
            
            // Add audio track if available
            if let localAudioTrack = self.localAudioTrack {
                builder.audioTracks = [localAudioTrack]
                print("✅ Added audio track to connection")
            } else {
                print("⚠️ No audio track available")
            }
        }
        
        room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
    }
    
    // MARK: - Disconnect

    func disconnect(cleanupMedia: Bool = true) {
        print("📞 Disconnecting from room...")
        room?.disconnect()
        
        if cleanupMedia {
            cleanupLocalMedia()
        }
    }
    private func cleanupLocalMedia() {
        print("🧹 Cleaning up local media...")
        
        // Stop camera capture
        if let camera = camera {
            camera.stopCapture()
        }
        
        localVideoTrack = nil
        localAudioTrack = nil
        camera = nil
        
        print("✅ Cleanup complete")
    }
    
    // MARK: - Media Controls
    
    func toggleLocalVideo() -> Bool {
        guard let localVideoTrack = localVideoTrack else {
            print("⚠️ No video track to toggle")
            return false
        }
        
        localVideoTrack.isEnabled = !localVideoTrack.isEnabled
        print("📹 Video \(localVideoTrack.isEnabled ? "enabled" : "disabled")")
        return localVideoTrack.isEnabled
    }
    
    func toggleLocalAudio() -> Bool {
        guard let localAudioTrack = localAudioTrack else {
            print("⚠️ No audio track to toggle")
            return false
        }
        
        localAudioTrack.isEnabled = !localAudioTrack.isEnabled
        print("🎤 Audio \(localAudioTrack.isEnabled ? "enabled" : "disabled")")
        return localAudioTrack.isEnabled
    }
    
    func flipCamera() {
        guard let camera = camera else {
            print("⚠️ No camera to flip")
            return
        }
        
        let newPosition: AVCaptureDevice.Position = camera.device?.position == .front ? .back : .front
        
        if let newDevice = CameraSource.captureDevice(position: newPosition) {
            camera.selectCaptureDevice(newDevice) { _, _, error in
                if let error = error {
                    print("❌ Failed to flip camera: \(error.localizedDescription)")
                } else {
                    print("✅ Camera flipped to \(newPosition == .front ? "front" : "back")")
                }
            }
        }
    }
}

// MARK: - RoomDelegate
extension VideoManager: RoomDelegate {
    func roomDidConnect(room: Room) {
        print("✅ Connected to room: \(room.name)")
        
        // Handle existing participants
        if let remoteParticipant = room.remoteParticipants.first {
            self.remoteParticipant = remoteParticipant
            remoteParticipant.delegate = self
            print("👤 Found existing participant: \(remoteParticipant.identity)")
        }
        
        delegate?.didConnectToRoom()
    }
    
    func roomDidDisconnect(room: Room, error: Error?) {
        print("📞 Disconnected from room")
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
extension VideoManager: RemoteParticipantDelegate {
    func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        print("📹 Participant \(participant.identity) published video track")
    }
    
    func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        print("📹 Participant \(participant.identity) unpublished video track")
    }
    
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        print("✅ Subscribed to video track from \(participant.identity)")
        delegate?.didSubscribeToVideoTrack(videoTrack: videoTrack, participant: participant)
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        print("📹 Unsubscribed from video track from \(participant.identity)")
    }
    
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        print("🎤 Subscribed to audio track from \(participant.identity)")
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        print("🎤 Unsubscribed from audio track from \(participant.identity)")
    }
}

// MARK: - CameraSourceDelegate
extension VideoManager: CameraSourceDelegate {
    func cameraSourceDidFailWithError(_ source: CameraSource, error: Error) {
        print("❌ Camera error: \(error.localizedDescription)")
    }
    
    func cameraSourceWasInterrupted(source: CameraSource, reason: AVCaptureSession.InterruptionReason) {
        print("⚠️ Camera interrupted: \(reason.rawValue)")
    }
    
    func cameraSourceInterruptionEnded(source: CameraSource) {
        print("✅ Camera interruption ended")
    }
}

