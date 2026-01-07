//
//  AudioCallViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 06/01/26.
//

import UIKit
import TwilioVideo

class AudioCallViewController: UIViewController {
    
    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 80
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let callerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "Connecting..."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "00:00"
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 40
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var muteButton: UIButton = {
        let button = createControlButton(
            image: UIImage(systemName: "mic.fill"),
            backgroundColor: .systemGray.withAlphaComponent(0.3)
        )
        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var speakerButton: UIButton = {
        let button = createControlButton(
            image: UIImage(systemName: "speaker.wave.2.fill"),
            backgroundColor: .systemGray.withAlphaComponent(0.3)
        )
        button.addTarget(self, action: #selector(speakerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var endCallButton: UIButton = {
        let button = createControlButton(
            image: UIImage(systemName: "phone.down.fill"),
            backgroundColor: .systemRed
        )
        button.addTarget(self, action: #selector(endCallButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    private let token: String
    private let roomName: String
    private let callerName: String
    private let callerImage: UIImage?
    
    private var isAudioMuted = false
    private var isSpeakerOn = false
    private var callDuration: TimeInterval = 0
    private var timer: Timer?
    
    // MARK: - Init
    init(token: String, roomName: String, callerName: String, callerImage: UIImage? = nil) {
        self.token = token
        self.roomName = roomName
        self.callerName = callerName
        self.callerImage = callerImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioCall()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        if isBeingDismissed {
            AudioCallManager.shared.disconnect()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        callerNameLabel.text = callerName
        
        if let image = callerImage {
            profileImageView.image = image
        } else {
            // Set placeholder with first letter
            let initials = String(callerName.prefix(1)).uppercased()
            profileImageView.backgroundColor = .systemPurple
            
            let label = UILabel()
            label.text = initials
            label.font = .systemFont(ofSize: 60, weight: .medium)
            label.textColor = .white
            label.textAlignment = .center
            label.frame = profileImageView.bounds
            profileImageView.addSubview(label)
        }
        
        view.addSubview(profileImageView)
        view.addSubview(callerNameLabel)
        view.addSubview(statusLabel)
        view.addSubview(durationLabel)
        view.addSubview(controlsStackView)
        
        controlsStackView.addArrangedSubview(muteButton)
        controlsStackView.addArrangedSubview(speakerButton)
        controlsStackView.addArrangedSubview(endCallButton)
        
        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            profileImageView.widthAnchor.constraint(equalToConstant: 160),
            profileImageView.heightAnchor.constraint(equalToConstant: 160),
            
            callerNameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30),
            callerNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            callerNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            statusLabel.topAnchor.constraint(equalTo: callerNameLabel.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            durationLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            controlsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            controlsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsStackView.heightAnchor.constraint(equalToConstant: 70),
            controlsStackView.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    private func setupAudioCall() {
        AudioCallManager.shared.delegate = self
        AudioCallManager.shared.setupLocalAudio()
        AudioCallManager.shared.connectToRoom(token: token, roomName: roomName)
    }
    
    private func createControlButton(image: UIImage?, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 35
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 70),
            button.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        return button
    }
    
    // MARK: - Actions
    @objc private func muteButtonTapped() {
        isAudioMuted = !AudioCallManager.shared.toggleLocalAudio()
        let imageName = isAudioMuted ? "mic.slash.fill" : "mic.fill"
        muteButton.setImage(UIImage(systemName: imageName), for: .normal)
        muteButton.backgroundColor = isAudioMuted ? .systemRed : .systemGray.withAlphaComponent(0.3)
    }
    
    @objc private func speakerButtonTapped() {
        isSpeakerOn.toggle()
        AudioCallManager.shared.toggleSpeaker(isSpeakerOn)
        let imageName = isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2.fill"
        speakerButton.setImage(UIImage(systemName: imageName), for: .normal)
        speakerButton.backgroundColor = isSpeakerOn ? .systemBlue : .systemGray.withAlphaComponent(0.3)
    }
    
    @objc private func endCallButtonTapped() {
        AudioCallManager.shared.disconnect()
        dismiss(animated: true)
    }
    
    // MARK: - Call Duration
    private func startCallTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.callDuration += 1
            self.updateDurationLabel()
        }
    }
    
    private func updateDurationLabel() {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AudioCallManagerDelegate
extension AudioCallViewController: AudioCallManagerDelegate {
    func didConnectToRoom() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Connected"
            
            UIView.animate(withDuration: 0.5, delay: 1.0) {
                self.statusLabel.alpha = 0
                self.durationLabel.alpha = 1
            }
            
            self.startCallTimer()
        }
    }
    
    func didDisconnectFromRoom() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.dismiss(animated: true)
        }
    }
    
    func didFailToConnectToRoom(error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Connection Failed",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true)
        }
    }
    
    func participantDidConnect(participant: RemoteParticipant) {
        print("Audio participant connected: \(participant.identity)")
    }
    
    func participantDidDisconnect(participant: RemoteParticipant) {
        DispatchQueue.main.async {
            self.statusLabel.alpha = 1
            self.statusLabel.text = "Call ended"
            self.durationLabel.alpha = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.dismiss(animated: true)
            }
        }
    }
}
