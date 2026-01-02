//
//  ChatMessageCell.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 30/12/25.
//

import UIKit
import AVKit

// MARK: - ChatMessageCellDelegate
protocol ChatMessageCellDelegate: AnyObject {
    func didTapImage(_ image: UIImage)
    func didTapVideo(_ videoURL: URL)
}

// MARK: - Chat Message Cell
class ChatMessageCell: UITableViewCell {
    
    weak var delegate: ChatMessageCellDelegate?
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let mediaImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let videoPlayButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 30
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let audioContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    // Container to hold message and time in same line for text messages
    private let textContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Audio UI Components - WhatsApp Style
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let audioWaveformView: AudioWaveformView = {
        let view = AudioWaveformView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Progress bar (thin line showing playback progress)
    private let audioProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemGreen
        progress.trackTintColor = .systemGray5
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        return progress
    }()

    private let audioDurationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        label.text = "0:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Audio time label (shown at bottom right like WhatsApp)
    private let audioTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Read receipts (checkmarks)
    private let readReceiptImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // Microphone icon for audio messages
    private let microphoneIconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        iv.image = UIImage(systemName: "mic.fill", withConfiguration: config)
        iv.tintColor = .systemGray2
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var mediaWidthConstraint: NSLayoutConstraint!
    private var mediaHeightConstraint: NSLayoutConstraint!
    
    // Text container constraints
    private var textContainerTopConstraint: NSLayoutConstraint!
    private var textContainerBottomConstraint: NSLayoutConstraint!
    
    // Message label constraints within text container
    private var messageLabelTrailingToTimeConstraint: NSLayoutConstraint!
    private var messageLabelTrailingToContainerConstraint: NSLayoutConstraint!
    
    // Media-related constraints
    private var mediaTopConstraint: NSLayoutConstraint!
    private var messageLabelTopToMediaConstraint: NSLayoutConstraint!
    private var timeLabelTopToMediaConstraint: NSLayoutConstraint!
    private var timeLabelTopToMessageConstraint: NSLayoutConstraint!
    
    private var timeLabelLeadingConstraint: NSLayoutConstraint!
    private var timeLabelTrailingConstraint: NSLayoutConstraint!
    
    // Time label position in text container
    private var timeLabelInlineLeadingConstraint: NSLayoutConstraint!
    private var timeLabelInlineBottomConstraint: NSLayoutConstraint!
    
    private var audioURL: URL?
    private var audioDuration: TimeInterval = 0
    
    // Timer for updating audio progress
    private var audioUpdateTimer: Timer?
    
    private var currentMessage: Message?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupAudioViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mediaImageView.image = nil
        messageLabel.text = nil
        currentMessage = nil
        
        // Stop timer and reset audio UI state
        audioUpdateTimer?.invalidate()
        audioUpdateTimer = nil
        updatePlayButtonState(isPlaying: false)
        audioWaveformView.updateProgress(0)
        audioProgressView.setProgress(0, animated: false)
        
        audioContainerView.isHidden = true
        audioURL = nil
        audioDuration = 0
        textContainer.isHidden = false
    }
    
    //MARK: - Setup Views
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(mediaImageView)
        bubbleView.addSubview(textContainer)
        textContainer.addSubview(messageLabel)
        textContainer.addSubview(timeLabel)
        mediaImageView.addSubview(videoPlayButton)
        
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        
        mediaWidthConstraint = mediaImageView.widthAnchor.constraint(equalToConstant: 200)
        mediaHeightConstraint = mediaImageView.heightAnchor.constraint(equalToConstant: 200)
        
        // Text container constraints
        textContainerTopConstraint = textContainer.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8)
        textContainerBottomConstraint = textContainer.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        
        // Media constraints
        mediaTopConstraint = mediaImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4)
        messageLabelTopToMediaConstraint = textContainer.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 8)
        
        // Time in separate row (for media messages)
        timeLabelTopToMediaConstraint = timeLabel.topAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: 4)
        timeLabelTopToMessageConstraint = timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4)
        timeLabelLeadingConstraint = timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12)
        timeLabelTrailingConstraint = timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        
        // Time inline with text (for text-only messages)
        timeLabelInlineLeadingConstraint = timeLabel.leadingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 8)
        timeLabelInlineBottomConstraint = timeLabel.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 0)
        
        // Message label constraints
        messageLabelTrailingToTimeConstraint = messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8)
        messageLabelTrailingToContainerConstraint = messageLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            // Media constraints
            mediaImageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),
            mediaImageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4),
            
            // Text container constraints
            textContainer.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            textContainer.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            // Message label in text container
            messageLabel.topAnchor.constraint(equalTo: textContainer.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            
            // Time label in text container (inline)
            timeLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            
            videoPlayButton.centerXAnchor.constraint(equalTo: mediaImageView.centerXAnchor),
            videoPlayButton.centerYAnchor.constraint(equalTo: mediaImageView.centerYAnchor),
            videoPlayButton.widthAnchor.constraint(equalToConstant: 60),
            videoPlayButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(mediaTapped))
        mediaImageView.addGestureRecognizer(imageTap)
        
        videoPlayButton.addTarget(self, action: #selector(mediaTapped), for: .touchUpInside)
    }
    
    //MARK: - Setup Audio Views (WhatsApp Style)
    private func setupAudioViews() {
        bubbleView.addSubview(audioContainerView)
        
        audioContainerView.addSubview(playButton)
        audioContainerView.addSubview(microphoneIconView)
        audioContainerView.addSubview(audioWaveformView)
        audioContainerView.addSubview(audioProgressView)
        audioContainerView.addSubview(audioDurationLabel)
        audioContainerView.addSubview(audioTimeLabel)
        audioContainerView.addSubview(readReceiptImageView)
        
        NSLayoutConstraint.activate([
            // Audio container
            audioContainerView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            audioContainerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            audioContainerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            audioContainerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            audioContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Play button (circular, left side)
            playButton.leadingAnchor.constraint(equalTo: audioContainerView.leadingAnchor, constant: 4),
            playButton.centerYAnchor.constraint(equalTo: audioContainerView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Microphone icon (next to play button, top)
            microphoneIconView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            microphoneIconView.topAnchor.constraint(equalTo: audioContainerView.topAnchor, constant: 8),
            microphoneIconView.widthAnchor.constraint(equalToConstant: 14),
            microphoneIconView.heightAnchor.constraint(equalToConstant: 14),
            
            // Waveform (center, takes up most space)
            audioWaveformView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            audioWaveformView.trailingAnchor.constraint(equalTo: audioContainerView.trailingAnchor, constant: -60),
            audioWaveformView.topAnchor.constraint(equalTo: microphoneIconView.bottomAnchor, constant: 4),
            audioWaveformView.heightAnchor.constraint(equalToConstant: 24),
            
            // Progress bar (overlays waveform at bottom)
            audioProgressView.leadingAnchor.constraint(equalTo: audioWaveformView.leadingAnchor),
            audioProgressView.trailingAnchor.constraint(equalTo: audioWaveformView.trailingAnchor),
            audioProgressView.bottomAnchor.constraint(equalTo: audioWaveformView.bottomAnchor),
            audioProgressView.heightAnchor.constraint(equalToConstant: 3),
            
            // Duration label (below waveform, left)
            audioDurationLabel.leadingAnchor.constraint(equalTo: audioWaveformView.leadingAnchor),
            audioDurationLabel.topAnchor.constraint(equalTo: audioWaveformView.bottomAnchor, constant: 2),
            
            // Time label (bottom right)
            audioTimeLabel.trailingAnchor.constraint(equalTo: audioContainerView.trailingAnchor, constant: -4),
            audioTimeLabel.bottomAnchor.constraint(equalTo: audioContainerView.bottomAnchor, constant: -4),
            
            // Read receipt (next to time label)
            readReceiptImageView.trailingAnchor.constraint(equalTo: audioTimeLabel.leadingAnchor, constant: -4),
            readReceiptImageView.centerYAnchor.constraint(equalTo: audioTimeLabel.centerYAnchor),
            readReceiptImageView.widthAnchor.constraint(equalToConstant: 16),
            readReceiptImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        playButton.addTarget(self, action: #selector(audioPlayTapped), for: .touchUpInside)
        
        // Setup completion callback
        setupAudioCompletionCallback()
    }
    
    private func setupAudioCompletionCallback() {
        AudioPlayerManager.shared.onPlaybackFinished = { [weak self] finishedURL in
            guard let self = self else { return }
            
            // Only update if this cell is showing the audio that finished
            guard self.audioURL == finishedURL else { return }
            
            DispatchQueue.main.async {
                self.resetAudioPlayback()
            }
        }
    }
    
    func configure(with message: Message) {
        currentMessage = message
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Stop any existing timer
        audioUpdateTimer?.invalidate()
        audioUpdateTimer = nil
        
        // Deactivate all dynamic constraints first
        textContainerTopConstraint.isActive = false
        textContainerBottomConstraint.isActive = false
        mediaTopConstraint.isActive = false
        messageLabelTopToMediaConstraint.isActive = false
        mediaWidthConstraint.isActive = false
        mediaHeightConstraint.isActive = false
        timeLabelTopToMediaConstraint.isActive = false
        timeLabelTopToMessageConstraint.isActive = false
        timeLabelLeadingConstraint.isActive = false
        timeLabelTrailingConstraint.isActive = false
        timeLabelInlineLeadingConstraint.isActive = false
        timeLabelInlineBottomConstraint.isActive = false
        messageLabelTrailingToTimeConstraint.isActive = false
        messageLabelTrailingToContainerConstraint.isActive = false
        
        // Reset visibility
        messageLabel.isHidden = false
        mediaImageView.isHidden = true
        videoPlayButton.isHidden = true
        mediaImageView.backgroundColor = .clear
        audioContainerView.isHidden = true
        textContainer.isHidden = false
        microphoneIconView.isHidden = true
        audioTimeLabel.isHidden = true
        readReceiptImageView.isHidden = true
        
        switch message.type {
        case .text(let text):
            messageLabel.text = text
            mediaImageView.isHidden = true
            audioContainerView.isHidden = true
            
            // Use inline time label layout
            textContainerTopConstraint.isActive = true
            textContainerBottomConstraint.isActive = true
            timeLabelInlineLeadingConstraint.isActive = true
            timeLabelInlineBottomConstraint.isActive = true
            messageLabelTrailingToTimeConstraint.isActive = true
            
        case .image(let image, let caption):
            audioContainerView.isHidden = true
            mediaImageView.isHidden = false
            mediaImageView.image = image
            
            // Calculate aspect ratio
            let aspectRatio = image.size.height / image.size.width
            let maxWidth: CGFloat = 200
            let maxHeight: CGFloat = 300
            
            let width = min(image.size.width, maxWidth)
            let height = min(width * aspectRatio, maxHeight)
            
            mediaWidthConstraint.constant = width
            mediaHeightConstraint.constant = height
            mediaWidthConstraint.isActive = true
            mediaHeightConstraint.isActive = true
            mediaTopConstraint.isActive = true
            
            if let caption = caption, !caption.isEmpty {
                messageLabel.text = caption
                messageLabelTopToMediaConstraint.isActive = true
                textContainerBottomConstraint.isActive = true
                timeLabelInlineLeadingConstraint.isActive = true
                timeLabelInlineBottomConstraint.isActive = true
                messageLabelTrailingToTimeConstraint.isActive = true
            } else {
                messageLabel.isHidden = true
                textContainer.isHidden = true
                timeLabelTopToMediaConstraint.isActive = true
                timeLabelLeadingConstraint.isActive = true
                timeLabelTrailingConstraint.isActive = true
                
                let timeLabelBottomConstraint = timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
                timeLabelBottomConstraint.isActive = true
            }
            
        case .video(_, let thumbnail, let caption):
            audioContainerView.isHidden = true
            mediaImageView.isHidden = false
            videoPlayButton.isHidden = false
            
            if let thumbnail = thumbnail {
                mediaImageView.image = thumbnail
                
                let aspectRatio = thumbnail.size.height / thumbnail.size.width
                let maxWidth: CGFloat = 200
                let maxHeight: CGFloat = 300
                
                let width = min(thumbnail.size.width, maxWidth)
                let height = min(width * aspectRatio, maxHeight)
                
                mediaWidthConstraint.constant = width
                mediaHeightConstraint.constant = height
            } else {
                mediaImageView.backgroundColor = .systemGray5
                mediaWidthConstraint.constant = 200
                mediaHeightConstraint.constant = 200
            }
            
            mediaWidthConstraint.isActive = true
            mediaHeightConstraint.isActive = true
            mediaTopConstraint.isActive = true
            
            if let caption = caption, !caption.isEmpty {
                messageLabel.text = caption
                messageLabelTopToMediaConstraint.isActive = true
                textContainerBottomConstraint.isActive = true
                timeLabelInlineLeadingConstraint.isActive = true
                timeLabelInlineBottomConstraint.isActive = true
                messageLabelTrailingToTimeConstraint.isActive = true
            } else {
                messageLabel.isHidden = true
                textContainer.isHidden = true
                timeLabelTopToMediaConstraint.isActive = true
                timeLabelLeadingConstraint.isActive = true
                timeLabelTrailingConstraint.isActive = true
                
                let timeLabelBottomConstraint = timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
                timeLabelBottomConstraint.isActive = true
            }
            
        case .audio(let url, let duration):
            // Hide other content
            mediaImageView.isHidden = true
            videoPlayButton.isHidden = true
            messageLabel.isHidden = true
            textContainer.isHidden = true
            
            // Show audio container and components
            audioContainerView.isHidden = false
            microphoneIconView.isHidden = false
            audioTimeLabel.isHidden = false
            
            audioURL = url
            audioDuration = duration
            
            // Set time label
            audioTimeLabel.text = formatter.string(from: message.timestamp)
            
            // Set duration
            audioDurationLabel.text = formatDuration(duration)
            audioWaveformView.generateWaveform()
            
            // Show read receipts for sent messages
            if message.isFromCurrentUser {
                readReceiptImageView.isHidden = false
                // Double checkmark (read)
//                let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
//                readReceiptImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
//                readReceiptImageView.tintColor = .systemBlue
            }
            
            // Check if this audio is currently playing
            if AudioPlayerManager.shared.isPlaying(url: url) {
                updatePlayButtonState(isPlaying: true)
                startAudioUpdateTimer()
                
                // Update current progress
                if let player = AudioPlayerManager.shared.audioPlayer {
                    let progress = player.currentTime / player.duration
                    audioWaveformView.updateProgress(progress)
                    audioProgressView.setProgress(Float(progress), animated: false)
                    let remaining = player.duration - player.currentTime
                    audioDurationLabel.text = formatDuration(remaining)
                }
            } else {
                updatePlayButtonState(isPlaying: false)
                audioWaveformView.updateProgress(0)
                audioProgressView.setProgress(0, animated: false)
                audioDurationLabel.text = formatDuration(duration)
            }
        }
        
        // Configure bubble appearance
        if message.isFromCurrentUser {
            bubbleView.backgroundColor = UIColor(hex: "#d9fdd4")
            messageLabel.textColor = .black
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            timeLabel.textAlignment = .right
            
            // Audio button color for sent messages
            if case .audio = message.type {
                playButton.backgroundColor = .systemGreen
                audioProgressView.progressTintColor = .systemGreen
                audioTimeLabel.textColor = .systemGray
                audioDurationLabel.textColor = .systemGray2
                microphoneIconView.tintColor = .systemGray2
            }
        } else {
            bubbleView.backgroundColor = .white
            messageLabel.textColor = .black
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            timeLabel.textAlignment = .left
            
            // Audio button color for received messages
            if case .audio = message.type {
                playButton.backgroundColor = .systemBlue
                audioProgressView.progressTintColor = .systemBlue
                audioTimeLabel.textColor = .systemGray
                audioDurationLabel.textColor = .systemGray2
                microphoneIconView.tintColor = .systemGray2
                readReceiptImageView.isHidden = true
            }
        }
    }
    
    private func startAudioUpdateTimer() {
        // Stop existing timer
        audioUpdateTimer?.invalidate()
        
        // Start new timer
        audioUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioPlayback()
        }
    }
    
    private func updateAudioPlayback() {
        guard let url = audioURL,
              AudioPlayerManager.shared.isPlaying(url: url),
              let player = AudioPlayerManager.shared.audioPlayer else {
            // Playback stopped - reset UI
            resetAudioPlayback()
            return
        }
        
        let currentTime = player.currentTime
        let duration = player.duration
        
        updateAudioProgress(currentTime: currentTime, duration: duration)
    }
    
    private func updatePlayButtonState(isPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }
    
    private func updateAudioProgress(currentTime: TimeInterval, duration: TimeInterval) {
        let progress = currentTime / duration
        audioWaveformView.updateProgress(progress)
        audioProgressView.setProgress(Float(progress), animated: true)
        
        let remaining = duration - currentTime
        audioDurationLabel.text = formatDuration(remaining)
    }
    
    private func resetAudioPlayback() {
        // Ensure we're on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.resetAudioPlayback()
            }
            return
        }
        
        updatePlayButtonState(isPlaying: false)
        audioWaveformView.updateProgress(0)
        audioProgressView.setProgress(0, animated: false)
        audioDurationLabel.text = formatDuration(audioDuration)
        
        // Stop timer
        audioUpdateTimer?.invalidate()
        audioUpdateTimer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    @objc private func mediaTapped() {
        guard let message = currentMessage else { return }
        
        switch message.type {
        case .image(let image, _):
            delegate?.didTapImage(image)
        case .video(let url, _, _):
            delegate?.didTapVideo(url)
        default:
            break
        }
    }
    
    @objc private func audioPlayTapped() {
        guard let url = audioURL else { return }
        
        if AudioPlayerManager.shared.isPlaying(url: url) {
            AudioPlayerManager.shared.pause()
            updatePlayButtonState(isPlaying: false)
            audioUpdateTimer?.invalidate()
            audioUpdateTimer = nil
        } else {
            do {
                try AudioPlayerManager.shared.play(url: url)
                updatePlayButtonState(isPlaying: true)
                startAudioUpdateTimer()
            } catch {
                print("Failed to play audio: \(error)")
            }
        }
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
