//
//  AudioRecordingManager.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 01/01/26.
//

import UIKit
import AVFoundation

// MARK: - Audio Recording Manager
class AudioRecordingManager: NSObject {
    
    static let shared = AudioRecordingManager()
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    
    var onRecordingUpdate: ((TimeInterval) -> Void)?
    var onRecordingComplete: ((URL?, TimeInterval) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    func startRecording() throws -> URL {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        // Create recording URL
        let filename = "voice_\(UUID().uuidString).m4a"
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        // Recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        // Start timer
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            self.onRecordingUpdate?(self.recordingDuration)
        }
        
        return audioURL
    }
    
    func stopRecording() -> (URL?, TimeInterval)? {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        guard let url = audioRecorder?.url else {
            audioRecorder?.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
            audioRecorder = nil
            recordingDuration = 0
            return nil
        }
        
        audioRecorder?.stop()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        let duration = recordingDuration
        
        audioRecorder = nil
        recordingDuration = 0
        
        return (url, duration)
    }
    
    func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        let url = audioRecorder?.url
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Delete the file
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        recordingDuration = 0
    }
    
    func getCurrentDuration() -> TimeInterval {
        return recordingDuration
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            onRecordingComplete?(nil, 0)
        }
    }
}

// MARK: - Voice Recording Button
class VoiceRecordingButton: UIButton {
    
    private let minRecordingDuration: TimeInterval = 1.0
    private let cancelThreshold: CGFloat = 100.0
    
    private var recordingStarted = false
    private var initialTouchPoint: CGPoint = .zero
    private var recordingURL: URL?
    
    var onRecordingStart: (() -> Void)?
    var onRecordingCancel: (() -> Void)?
    var onRecordingSend: ((URL, TimeInterval) -> Void)?
    var onSlideUpdate: ((CGFloat) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        setImage(UIImage(systemName: "mic.fill"), for: .normal)
        tintColor = .systemBlue
        backgroundColor = .systemGray6
        layer.cornerRadius = 22
        
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(touchDragExit), for: .touchDragExit)
        addTarget(self, action: #selector(touchDragInside), for: .touchDragInside)
    }
    
    @objc private func touchDown(_ sender: UIButton, event: UIEvent) {
        guard let touch = event.touches(for: sender)?.first else { return }
        initialTouchPoint = touch.location(in: self)
        
        AudioRecordingManager.shared.checkPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.startRecording()
            } else {
                self.showPermissionAlert()
            }
        }
    }
    
    @objc private func touchUpInside(_ sender: UIButton, event: UIEvent) {
        if recordingStarted {
            stopRecording(cancelled: false)
        }
    }
    
    @objc private func touchDragExit(_ sender: UIButton, event: UIEvent) {
        if recordingStarted {
            stopRecording(cancelled: true)
        }
    }
    
    @objc private func touchDragInside(_ sender: UIButton, event: UIEvent) {
        guard recordingStarted, let touch = event.touches(for: sender)?.first else { return }
        
        let currentPoint = touch.location(in: self)
        let slideDistance = initialTouchPoint.x - currentPoint.x
        
        if slideDistance > cancelThreshold {
            stopRecording(cancelled: true)
        } else {
            let progress = min(slideDistance / cancelThreshold, 1.0)
            onSlideUpdate?(progress)
        }
    }
    
    private func startRecording() {
        do {
            recordingURL = try AudioRecordingManager.shared.startRecording()
            recordingStarted = true
            
            // Visual feedback
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                self.backgroundColor = .systemRed
            }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            onRecordingStart?()
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording(cancelled: Bool) {
        guard recordingStarted else { return }
        recordingStarted = false
        
        // Reset visual state
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
            self.backgroundColor = .systemGray6
        }
        
        if cancelled {
            AudioRecordingManager.shared.cancelRecording()
            onRecordingCancel?()
        } else {
            let duration = AudioRecordingManager.shared.getCurrentDuration()
            
            if duration < minRecordingDuration {
                // Too short, cancel
                AudioRecordingManager.shared.cancelRecording()
                showTooShortAlert()
            } else {
                AudioRecordingManager.shared.stopRecording()
                
                if let url = recordingURL {
                    onRecordingSend?(url, duration)
                }
            }
        }
        
        recordingURL = nil
    }
    
    private func showPermissionAlert() {
        guard let viewController = self.findViewController() else { return }
        
        let alert = UIAlertController(
            title: "Microphone Access Required",
            message: "Please enable microphone access in Settings to record voice messages.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    private func showTooShortAlert() {
        guard let viewController = self.findViewController() else { return }
        
        let alert = UIAlertController(
            title: "Recording Too Short",
            message: "Please hold for at least 1 second to send a voice message.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - Recording Overlay View
class RecordingOverlayView: UIView {
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cancelLabel: UILabel = {
        let label = UILabel()
        label.text = "← Slide to cancel"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let redDot: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        
        addSubview(redDot)
        addSubview(timeLabel)
        addSubview(cancelLabel)
        
        NSLayoutConstraint.activate([
            redDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            redDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            redDot.widthAnchor.constraint(equalToConstant: 8),
            redDot.heightAnchor.constraint(equalToConstant: 8),
            
            timeLabel.leadingAnchor.constraint(equalTo: redDot.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            cancelLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cancelLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // FIX: Control animation lifecycle
    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopBlinking()
            } else {
                startBlinking()
            }
        }
    }
    
    func updateTime(_ duration: TimeInterval) {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    func updateCancelProgress(_ progress: CGFloat) {
        cancelLabel.alpha = 1.0 - progress
        cancelLabel.transform = CGAffineTransform(translationX: -progress * 50, y: 0)
    }
    
    private func startBlinking() {
        redDot.layer.removeAllAnimations()
        redDot.alpha = 1.0
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction]
        ) {
            self.redDot.alpha = 0.3
        }
    }
    
    private func stopBlinking() {
        redDot.layer.removeAllAnimations()
        redDot.alpha = 1.0
    }
}

